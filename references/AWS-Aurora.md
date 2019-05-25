# [re:Ivent2018 Deep Dive on Amazon Aurora with PostgreSQL Compatibility](https://youtu.be/3PshvYmTv9M)

RDS PostgreSQL의 경우에는 PostgreSQL가 EC2 instance에 올라가고 EBS Volume이 붙어 있는 구조이다.
Aurora PostgreSQL는 Aurora Storage가 연결되어 있다.

RDS PostgreSQL과 Aurora PostgreSQL은 아래와 같이 동일한 extensions 제공한다.
- Backup/Recovery - PITR
- HA & Durability
- IAM Auth
- Read replicas
- Cross region snapshots
- Scale Compute - Online scale storage

Cross Region replication이랑 Outbound logical replication은 호환되도록 작업중

## Log based storage

### PostgreSQL

여래 개의 commit을 group해서 Log buffer에 한꺼번에 들어간다.
Log buffer가 flush되기 전까지는 다른 queued work가 기다려야한다.
log buffer가 flush되어서 storage에 저장이 되고, acknowledge를 하면 
이제 log buffer에 다음 queue work 들어갈 수 있게 된다. 
이게 bottleneck이 된다.

Queued Work \
Log Buffer \
Storage

group commit은 여러 개의 transaction들을 batch로 commit할 수 있도록 한다. 
commit delay라는 설정이 있다. group commit leader가 lock을 acquire하고 group follower가 commit을 queue에 얼마동안 쌓을지 결정하게 된다.
이렇게 다른 process가 WAL buffer에 commit record를 추가하고 이 leader가 flush해서 WAL segment에 저장되게 하는 것이다.
group commit은 WAL segment에 flushing하는 작업의 부하를 덜어줄 수 있는 것.

### Aurora
 
반면에 Aurora는 log buffer가 없고, storage에 queued work가 바로 들어간다.
6개의 storage node에서 4개가 acknowledge를 하면 client한테 응답
ordered system이라서 이전의 transaction이 4개 이상의 acknowledge를 못받으면
다음 transaction이 4개 이상을 받아도 기다려야 된다.

#### 1. Aurora에는 기존 PostgreSQL처럼 log buffer때문에 bottleneck이 생긴지 않는다.

## Writing less

### PostgreSQL

PostgreSQL에는 WAL(Write Ahead Logging)이라는 것이 존재한다. PostgreSQL는 Shared buffer를 사용하는데, tuple들이 memory에 저장되어 있다가
Persistent storage에 주기적으로 flushing 된다. 따라서 중간에 서버가 다운되거나 하면 memory에 있던 정보들이 날라가게된다. 
Durability를 위해서 WAL에 transaction history가 저장된다.

background process로 checkpoint하는데, 장애가 생겨서 복구를 해야될 때 시작해야 되는 시점을 기록하게 된다. 그리고 shared buffer에 있는 dirty pages가 flushing된다.

근데 OS단에서 background writer process가 dirty page를 쓰는 도중에 에러가 나서 corrupted page가 발생할 수 있다.
이렇게 문제가 생긴 page에다가 WAL에 기록된 log를 다시 replay할 수가 없다. 그래서 Full page writes라는 기능이 있는데,
checkpoint하고 처음 바뀌는 page를 통째로 저장한다. 그래서 이렇게 corrupted page가 발생해도 checkpoint시점으로 정상적인 page정보를 아니깐,
여기에다가 WAL에 기록된 log를 replay해서 복구하게 된다.

PostgreSQL는 default block size 8K이고 Linux에서 4K라서 뭔가 crash가 발생해서 PostgreSQL의 절반의 데이터만 Disk에 저장될 수도 있다.
이런 경우에 corrupted page가 생기는거고 full page writes기능으로 복구가 될 수 있다.

### Aurora

Aurora read/write node가 update를 하면 in-memory queue에 들어갔다가 on disk에 저장되는 update queue로 옮겨가고 이때
client acknowledge를 한다. 여기까지 synchronous하게 동작하고 그다음부터는 background로 동작한다.

acknowledge하고 이제 Data block에 Coalesce(새로 들어온 데이터를 한 block으로 합치는 작업인것 같다)하고 Hog log로도 보내져서
다른 node간에 새로운 update를 적용하게 된다.

Read node는 이제 Coalesce된 data block에서 바로 읽게 된다.

#### 2. Aurora는 기존 PostgreSQL처럼 checkpoint, Full page writes 기능이 필요없다. 그리고 계속해서 이렇게 data block를 업데이트하기 때문에 Long crash recovery가 아니다.  

## performance

### Insert를 1초에 25,000번 이상하는 benchmark

PostgreSQL에서는 점점 데이터가 쌓이면서 checkpoint에서 건드리게 되는 block도 많아지고, full page writes에서 write하는 page의 크기도 커지니깐 성능이 급격하게 떨어진다.

### crash recovery

PostgreSQL에서 write이 많아지면 Redo point부터 recovery해야되는 양도 많아지니깐 느려지겠지

#### 위에서 설명한 것처럼 Aurora에서는 full page writes가 필요없고 지속적으로 recovery를 하니깐, 이부분에서 훨씬 뛰어난 performance를 보일 수 있다.

## Vacuum

PostgreSQL에서 Vacuum process로 dead tuple(Delete된)은 table file의 page에서 제거된다. Visibility map은 이 Vacuum proccess를 개선한 방법이다.

aurora에서 write성능을 2~3배 향상시켰다고 했는데, Vaccum은 그대로면 이건 Disaster라고 말한다. 그래서 Aurora에서는
Vacuum해야할 block address를 가져와서 batch로 Vacuum한다.

#### 3. Aurora에서 Vacuum 성능도 향상시켰다.

## Caching

OS랑 PostgreSQL process가 쓰는 메모리가 있고, 이제 shared buffer영역과 Linux의 page caches영역이 있는데, 
shared buffer와 page cache영역에 중복되는 buffer가 생긴다. Shared buffer 영역이 크면 Transaction per second가 향상되는데,
PostgreSQL에서도 75% shared buffer를 사용하면 Aurora의 75% cache랑 비슷한 성능을 보인다. 문제는 PogreSQL 프로세스가 죽으면 이제
shared buffer는 날라가지만 page cache부분을 살아남게 된다. 하지만 shared buffer만 75%를 사용하면 다 날라가게 되는데,
Aurora는 PostgreSQL 프로세스와 독립적으로 살아남는 shared buffer를 구성하고 있다.

#### 4. Aurora에서는 75% shared buffer를 사용하고 PSQL process가 죽어도 별도로 살아남는 cache이다.

## Replica

RDS에서 replica는 RW node에서 update가 발생하면 RW node에 있는 EBS에 저장하고 Read Node에게 async하게 전달하면,
Read Node의 EBS에 Update하는 작업을 진행하게 된다.

하지만 Aurora에서는 Aurora Storage layer를 공유하고, RW node에서 async하게 Read node에 전달하면 Read Node의 memory에 있는 정보만 update한다.

RW Node에 네가지의 table이 있고, 다 수정된다. 그리고 Read only Node가 있다.
Read only node에서 이미 table A를 read했다고 하면 memory에 table A의 정보가 있다. 근데 RDS에서 async replication을 하면 수정된 모든 table이 memory에 적용되게 된다.
하지만, Aurora에서는 table A만 memory에서 update가 일어난다.

그래서 performance benchmark에서 Read only node가 read를 계속 하고 있을 때, RW node에 대량의 update가 발생하게 시키면,
replication delay가 RDS에서 급격하게 늘어나는 것을 보여준다.

#### 5. Aurora에서는 replica가 read-only의 memory만 update된다.

## Cluster Cache Management Feature

Failover가 발생해서 Read-only가 RW node역할을 넘겨받는다. 근데 failover되서 Read-only node가 write를 다시 시작하는데는
DNS까지 포함해서 몇십초면 되는데, cache가 warm up이 안되서 높은 TPS로 다시 올라가는데 훨씬 더 많은 시간이 걸린다.
 
cluster 단위의 parameter에서 apg_ccm_enabled를 on해주고, priority를 설정해서 read node의 cache상황을 RW node와 비슷하게 가져가도록 할 수 있다.

## Fast Clone

Clone을 만들어서 Primary storage의 data를 가리키기만 할 수 있다.
가리키는 primary storage의 data가 update되면 clone에 반영되고, 추가되는 data는 반영안된다.
그리고 clone에서 새로 저장되거나 update primary에 반영이 안되고.

🤔 테스트할 때 Fast Clone을 사용해볼 수 있을까?

## Logical replication support
- V10에서는 publish/subscribe to another PostgreSQL instance

## Cross region replication

## Query Plan Management

# [Deep Dive on Amazon Aurora with MySQL Compatibility](https://youtu.be/U42mC_iKSBg)

## Traditional database architecture

SQL
Transactions
Caching
Logging
Local storage

local storage => network storage

Traditional Distributed Database stack

Sharding

Shared nothing

Shared Disk

Aurora distributed architecture

- Push Log applicator to Storage
=> contruct pages from the log themselves

traditional engine에서는 log랑 page를 write해야 하는데,
aurora only write log => less I/O, no checkpoint, cache eviction, background flushing

- 4/6 Write Quorum & Locak tracking

when storage receive write they accept. no voting involved

write performance

read scale out

AZ + 1 failure tolerance

Instant database redo recovery

# log applicator

master에 transaction이 시작되면,
6개의 storage에 전달되고 reader에게도 async하게 replication 전달

mysql에서 binlog로 변경된게 replica에 전달되서 replica data volume에
저장하기 때문에 wirte I/O가 발생한다.

aurora는 shared storage를 그냥 reader가 읽기만 하면 되니깐 write I/O가 발생안하는

전통적인 mysql에서

accumulate the set of log records => log buffer=> group commit
as soon as flushed you acknowledge back to client

- don't have checkpoints because construct page from the logs
- out of order flush
- no have heavy weight consensus

mysql thread model => connection당 thread생성

Aurora는 thread pool with event based eople and latch free task queue

Mysql lock manager

any update will lock the whole lock table

checkpoint를 크게하면 Write/s는 좋아지는데 recovery time이 길어진다.

## Exsiting Multi-master solutions

Distributed lock manager

Heavyweight synchronization: pessimistic and negative scaling

Global ordering with read-write set

Global entity: scaling bottleneck

paxos leader with 2PC

Heavy weight consensus protocol : Hot partitions and struggle with cross parition queries

CockroachDB가 여기에 포함되는구나.