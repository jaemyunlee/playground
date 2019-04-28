# [Amazon DynamoDB Deep Dive: Advanced Design Patterns for DynamoDB](https://youtu.be/HaEPXoXVf2k)

## Denormalization, complex query

> It's important to understand why we built the relational database and we did it because storage was extremely expensive.

Storage가 비싸던 시절에 RDBMS에서는 normalization을 통해서 비용을 줄일 수 있었다. 
하지만 complex query(여러가지 Table이 Join되는)는 CPU사용을 증가시킨다. 현재는 Data center에서
가장 비싼 것은 Storage가 아니라 CPU이다.


| SQL                   | NoSQL                     |
|-----------------------|---------------------------|
| Optimized for storage | Optimized for compute     |
| Normalized/relational | Denormalized/hierarchical |
| Ad hoc queries        | Instantiated views        |
| Scale vertically      | Scale horizontally        |
| Good for OLAP         | Built for OLTP at scale   |

## NoSQL database is flexible?

> One of the things I hear a lot is use NoSQL because It's very flexible.
I've done a thousand NoSQL applications I can tell you nothing could be further from the truth.
NoSQL database is not a flexible database. It's an efficient database.

NoSQL로 data modeling을 할 때 Access pattern에 따라서 조정해야 하고, Service와 강한 coupling을 가지기 때문에 
flexible database와는 거리가 멀다고 말한다. Access pattern이 반복적이고 일관된 경우에 NoSQL이 적합하다.

Tenets of NoSQL data modeling
- Understand the use case
    - Nature of the application
        - OLTP / OLAP / DSS
    - Define the Entity-Relationship Model
    - Identify Data Life Cycle
        - TTL, Backup/Archival, etc.
- Define the access patterns
    - Read/Write workloads
        - Identify data sources
        - Define query aggregations
        - Document all workflows
- Data-modeling
    - Avoid relational design patterns, use one table
        - 1 application service = 1 table
            - Reduce round trips
            - Simplify access patterns
        - Identify Primary keys
            - How will items be inserted and read?
            - Overload items into partitions
        - Define Indexes for secondary access patterns
- Review -> Repeat -> Review

## composite keys

### A.Query Filter

```
SELECT * FROM Game
WHERE Opponent='Bob'
ORDER BY Date DESC
FILTER ON Status='PENDING'
```

Sort condition은 읽기 전에 적용되고, filter condition은 읽은 후에 적용된다.
위에서는 Sort condition으로 내림차순으로 정렬하고, Filter condition으로 PENDING인 Item를 가져온다.
Item에서 다 읽고 거기서 filter를 적용하기 때문에 Consumed RCU가 많아진다.

### B.Composite keys
```
SELECT * FROM Game
WHERE Opponent='Bob'
AND StatusDate BEGINS_WITH 'PENDING'
```

Composite key로 date와 status를 PENDING_2019-01-01로 구성하면,
위에처럼 Sort condition으로 PENDING status인 item를 더욱 효과적으로 가져올 수 있다.

## Relational Transactions

Amazon의 Iternal service의 예를 설명한다.
Resolver Group이 n:n으로 Contact와 Configuration Item이랑 relation을 가지고 있는데,
아래처럼 DynamoDB schema를 구성할 수 있다.

Transaction Workflows
- Add Config Items to Resolver Groups
- Update Config Item status
- Add Contacts To Resolver Groups

### Table

|partition|sort|
|---------|----|
|contact_1|resolver_1|
|contact_1|resolver_2|
|contact_2|resolver_1|
|contact_2|resolver_2|
|resolver_1|configurationItemA UUID|
|resolver_1|configurationItemB UUID|
|resolver_1|metadata|
|resolver_2|configurationItemA UUID|
|resolver_2|configurationItemB UUID|
|resolver_2|metadata|

이렇게 Schema를 구성하고 위처럼 Item이 있을 때, ConfigurationItem update를 위해서
transaction이 필요하다. 두개의 resolver에 있는 configurationItemA을 transactions API로 update를 할 수 있겠다.

Denormalized된 contact에서도 email주소가 바뀌거나 하면, 여러 Item을 동시에 Update할 경우가 생긴다.
이것도 Transactions API를 사용할 수 있겠다.

TransactionWriteItems
- Synchronous update, put, delete, and check
    - Atomic
    - Automated Rollbacks
- Up to 10 items within a transaction
- Supports multiple tables
- Complex conidtional checks

🤔 TransactionWriteItems의 경우 10개 Items limit이 있다. 위의 스키마에서는 2개의 Item만 Update하는 상황이었지만,
10개 이상의 Item이 Transactional하게 update되야되는 상황이 될 수 있는지 고려하고 Schema를 짜야겠네? 

### GSI

|sort|partition|
|---------|----|
|resolver_1|contact_1|
|resolver_2|contact_1|
|resolver_1|contact_2|
|resolver_2|contact_2|
|configurationItemA UUID|resolver_1|
|configurationItemB UUID|resolver_1|
|metadata|resolver_1|
|configurationItemA UUID|resolver_2|
|configurationItemB UUID|resolver_2|
|metadata|resolver_2|

GSI를 위처럼 구성해서 resolver group별로 contact를 가져올 수도 있고,
configuration group별로 resolver group를 가져올 수 있도록 구성할 수 있다.

## Hierarchical Data Structure as Items

- Use composite sort key to define a hierarchy
- Highly selective queries with sort conditions
- Reduce query complexity

|partition|sort|Attributes|
|---------|----|----------|
|USA|NY#NYC#JFK11|Address1|
|USA|NY#NYC#JFK11|Address2|

Country > State > City > Office로 되어 있는 데이터 구조에서 composite key로 간단하게 구성할 수 있다.

## Access pattern을 파악하는 것이 중요하겠다

마지막 예제로 더 복잡한 data relationship을 보여주는데, 20개의 access pattern을 리스트업하고,
그걸 하나의 Table와 GSI 2개로 구성하였다.

이렇게 access pattern별로 DynamoDB schema를 구성하는 것을 보면서 왜 NoSQL database가 
service와 coupling되었다는 것을 이해할 수 있다.

## 기타

### consistent & low latency response with high traffic
Reinvent의 Amazon DynamoDB Under the Hood 강연에서 request router와 storage nodes들이 distribute하게 
엄청나게 많다고 설명했다. request router는 어느 storage node가 leader node이고 partition정보들을 가져오게 되는데,
dynamoDB에 request가 많으면 이렇게 distributed한 request router에 partition 정보들이 캐시가 된다.
그래서 consistent하고 low latency response가 된다고 한다.

### strong consistency read

GetItem할 때 eventual consistency read는 random하게 storage node를 선택하는 것이고,
strong consistency read는 leader storage node를 읽는 것이었다.

### GSI can throttle table write actions

GSI update는 eventually consistent이다. 이제 Table에 write action이 생기면 GSI에 전달되어서
update가 되게 되는데, Table의 write되는 load를 못 따라가게 되면 table이 GSI가 update할 수 있도록 write를 막게 된다.
GSI에 충분한 write capaticy가 없으면 table이 throttle될 수 있는 것이다. 그래서 Table이랑 GSI의 WCU를 동일하게 가져가라고 하는 것이다.
LSI는 stronly consistent하다.

### DynamoDB stream + Lambda

여기서도 DynamoDB stream을 활용하여서 DynamoDB proccess 밖에서 다양한 작업을 하는 것을 설명한다.
가장 일반적으로 Lambda를 붙여서 computed aggregation(average나 sum등 )을 다른 table에 write하는 방법이다.

근데 여기서 high velociy, 즉 load가 많으면 오히려 Lambda를 사용하는 것이 비용적으로 불리할 수 있다.
이럴 경우에는 EC2에다가 static stream reader service를 구성하는게 더 합리적일 수 있다.

### OLAP vs OLTP

맨날 약어를 까먹는다. 
- Online Analytical Processing
- Online transaction processing

---

# [AWS re:Invent 2018: Amazon DynamoDB Under the Hood](https://youtu.be/yvBR71D0nAQ)

DynamoDB가 어떻게 작동하는지 깊이 고민해보지 않았는데, 이 강연을 듣고 여러가지 DynamoDB 작동방식을 더 잘 이해할 수 있었다.

## DynamoDB flow

Client -> Network -> request router -> storage nodes

Request router는 stateless한 Public facing API for DynamoDB라고 할 수 있다.
request router는 authentication system과 partition metadata system과 통신한다.

### authentication system

authentication system에서 authentication이 되면 request router는 authorize를 한다.

### partition metadata system

partition metadata system으로부터는 어떤 storage node가 어떤 partition에서 leader node인지 정보를 얻는다.

### Leader storage nodes

DynamoDB는 HA를 위해서 다른 서비스처럼 다른 AZ에 있는 3개의 storage node에 Item을 보관한다.
storage node중에는 leader node가 있고, 두 개의 peer node에게 leader node가 정상적으로 작동하고 있다고
신호를 보내게 된다. 특정 횟수만큼 이러한 신호를 못 받게 되면 peer node는 leader가 문제가 있다고 판단하고,
새로운 leader node를 선출하고 선출된 peer node가 leader node 역할을 위임받는다.

## GetItem, PutItem

### PutItem

PutItem은 최종적으로 3개의 storage node에 data를 저장한다.(각각 storage는 다른 AZ에 속하게 되고)
하지만 두개의 storage에 저장이 완료되면 client는 response를 얻게 된다.
Requester router가 leader storage node에 전달하면 leader storage가 data를 저장하고 다른 peer storage node에게 
전파한다. 하나의 peer storage node부터 acknowledge를 전달받으면 응답을 바로 하게 되고, 응답 후에 세번째 peer node에 전파가 될 수 있다.

leader storage는 항상 최신의 데이터를 저장하고 있고, leader storage는 paxos라는 protocol? 방식?으로 결정된다.

### GetItem

getItem을 할 때는 random하게 storage node를 선택해서 해당 item를 가져온다.
그런데 위에서 설명한 것처럼 세 개의 노드 중에 두개의 노드에 data가 저장되면 응답하기 때문에, 나머지 하나의 노드에 아직 저장되지 않은 상태에서도
응답을 하게 된다. getItem에서 이렇게 아직 data를 저장하지 못한 노드에서 item를 가져오게 되면 최신의 data를 못가져 올 수도 있다.
경우에 따라서는 예측할 수 없는 지연이 있을 수 있다. 예를 들어서 network에 문제가 있을 수도 있고, storage node가 reboot되고 다시 repair되는 상황일 수도 있다.

이 강연에서는 strong consistency하게 read하는 것은 설명하지 않고 있다. read option중에 consistent read를 True하면,
leader node에서 get를 하게 된다. 

## Storage node

Storage node
- B-tree
- Replication logs

Auto Admin
- Partition Repair
- Create Tables
- Tables Provisioning
- Split Partition

auto admin이 storage nodes를 체크하고 fail되면 repair한다. 정상적인 storage node에서 replication logs를 카피하고
replication logs를 B-tree에 적용한다.

## Secondary index

idependent from base table

Client - network - RR -> Base Table -> Log Propogator -> Index

Log propogator는 Base table의 replication logs를 watching하면서 update index partition을 한다.
액션이 Base Table의 Item을 update하면 Index에서는 Old index에서 remove하고 new index에서 write한다.

## Token bucket Algorithm

### unbalanced load

이럴때 300 RCU인데 세 개의 partition이 있어서 100개씩 token bucket이 생기는데
여기서 hot partition이 있어서 100을 넘어가면 throttling이 걸린다. 전체 세 개의 partition이 fully 300을
쓰는 것도 아닌데 throttling이 생길 수 있는 것이다.

### Adaptive capacity

Adaptive capacity가 Multiplier로 조정해서 provisioning한 capacity만큼 쓸 수 있게 해준다.
PID controller로 unbalanced load에 따라서 Multiplier를 조정하게 된다. 특정 partition은 
이 조정된 Mutiplier로 unbalance문제로 생길 수 있는 throttling이 없이 더 많은 RCU를 사용할 수 있게 된다.

PID controller

🤔 자동제어 시간에 PID controller 공부했었는데 오랜만에 들으니 반갑다.

PID inputs
- Consumed Capacity
- Provisioned Capacity
- Throttling Rate
- Current Multiplier   

Auto Scaling

parition별로 balance하게 하다가 bursting도 있고, PID multiplier로 조정

## Backup and restore
- point in Time
- On demand backup

Q: Where to durably store backups?
A: S3

replication logs를 일정 크기로 묶어서 S3에 저장을 한다. 그리고 b-tree는 snapshot을 한다.
이제 Point in time으로 restore를 하게 되면 그 시점에서 세 개의 partition으로부터 저장하고 있던
replication logs와 snapshot을 사용하게 된다. restore하고 싶은 시점에서 가까운 snapshot부터 
replication logs들을 가지고 복구하게 되는 것이다. point in time을 enable하면 특정 시점에서 복구 할 수 있도록 S3에 저장된 replication logs와 snapshot을 가지고 있어야 한다.

## DynamoDB streams

replication logs가 Kenesis와 같은 기술로 streaming되는 것이다.

- All table mutations(Put, Update, Delete)
- No Duplicates
- In Order(By Key)
- New and Old Item Image available

## Global table

### conflict resolution

Last writer wins

muti region master가 같은 item을 동시에 update하면 마지막에 update하는 data가 된다.

---

# [AWS re:Invent 2018: A Deep Dive into What's New for Amazon DynamoDB](https://youtu.be/eTbBdXJq8ss)

## Advancements over the last 21 months

- 2017
    - TTL
    - VPC endpoints
    - DAX
    - Auto scaling
    - Global tables
    - On-demand backup
    - Encryption at rest
- 2018
    - Point-in-time recovery
    - 99.999% SLA
    - Adaptive capacity
    - Transactions
    - On-demand