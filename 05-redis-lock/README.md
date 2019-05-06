# Distributed locking with Redis

Redis에서 lock을 구현하는 방법들을 살펴보았다.

- MULTI, EXEC, WATCH를 이용한 lock
- SETNX를 이용한 lock
- Redlock

## MULTI, EXEC, WATCH를 이용한 lock

Redis에서 MULTI와 EXEC을 통해서 Transaction을 구현할 수 있다. 여기에 WATCH를 추가하여 간단한 Lock을 구현할 수 있다.


```
WATCH mykey
val = GET mykey
val = val + 1
MULTI
SET mykey $val
EXEC
```

위의 예제에서 mykey라는 이름의 key를 WATCH하고 있다.
WATCH 명령어부터 EXEC 명령어가 실행될 때까지 다른 Client가 mykey를 변경하게 되면,
이 Transaction은 Fail하게 된다. 이 방법은 Optimistic locking 방법으로 다른 Client가 내가 읽는 도중에
값을 변경하지 않는 것을 가정한다. 

## SETNX를 이용한 lock

### acquire

SETNX는 이미 SET된 key가 있으면 0을 return하고, 없으면 key를 SET하고 1을 반환한다.
이것을 이용하여 간단하게 lock을 구현할 수 있다. 한 Client가 SETNX로 먼저 key를 SET하면 lock aquire한 것이 되고,
나머지 Client가 이후에 SETNX를 하면 0을 받아서 lock이 걸린 걸 알게 된다.

### release

Lock을 aquire한 Client는 UUID와 같은 unique한 value를 key에 저장한다. 그리고 release할 때,
그 key의 value가 lock을 aquire한 Client가 가지고 있는 value 같은지 확인하고 해당 key를 DEL한다.

### deadlock 문제

Client가 lock aquire하고 장애가 생겨서 release를 못하는 경우가 발생할 수 있다.
이런 장애가 발생하면 위의 경우에는 deadlock이 발생할 수 있다.

### 해결책

- dealock를 방지하기 위해서 key를 set할 때 TTL를 걸어준다.
- SETNX로 key를 set할 때 value를 현재로부터 valid한 timeout 값을 넣을 수 있다.
SETNX로 0을 받으면, value를 GET해서 expire된 lock이 아닌지 확인한다. expire된게 확인되면 GETSET으로
새로운 timeout값을 넣는데, GETSET으로 하는 이유는 race condition을 방지하기 위함이다.
GETSET으로 old 값을 받았을 때 시간이 expire된 값이면 정상적으로 lock을 aquire했다고 볼 수 있다.

### 다른 문제

Single master node일 때 이 master node에 문제가 생기면 이 시스템은 완전 셧 다운된다. 그래서 replica를 둬서 master 노드가 문제가 생겼을 때,
replica가 master를 넘겨받아서 계속 실행될 수 있게 한다. 하지만 master와 replica간의 데이터 복사는 Asynchronous하게 작동된다.
그래서 만약 master에 key를 SET하고 replica에 복제 못한 상태에서 master node가 죽으면 replica에서 같은 lock을 aquire할 수 있게 된다.

## RedLock

RedLock은 위에서 설명한 방법처럼 lock aquire는 SETNX와 TTL를 걸어서 하고, release는 unique한 value를 체크하고 DEL하는 방법이랑 동일하다. 
하지만 Redlock은 replica를 사용하지 않는 N개의 독립적인 Redis Master node를 이용한다.
 
```
SET resource_name my_random_value NX PX 30000
```

```
if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del",KEYS[1])
else
    return 0
end
```

이 방법은 N개의 독립적인 Redis Master node의 과반수에서 lock aquire할 수 있으면 lock이 되었다고 판단한다.
N개의 독립적인 Redis master node들을 순차적으로 동일한 resource_name, random_value와 TTL 값으로 SETNX 된다.
중간에 문제가 있는 node들이 있을 수 있는데, N/2 + 1 개의 Node에서 SETNX를 성공하면 lock이 acquire되었다고 본다.
TTL 시간 이후에는 lock이 자동으로 release된다. 그리고 node들은 약간은 다른 time으로 set이 된다.
따라서 N개의 node에서 N/2 + 1 개의 set이 되는 시간이 TTL - acquire시작 time - acquire완료 time - clock drift
보다 작아야한다. 이 시간이 validity time이 된다.

### python으로 redlock을 구현한 redlock-py

Python으로 RedLock을 구현한 [redlock-py](https://github.com/SPSCommerce/redlock-py)를 코드를 살펴보았다.

#### Lock

##### start time 

`start_time = int(time.time() * 1000)`

##### set N nodes

이상적으로는 N개의 node에 multiplexing으로 동시에 SET를 하는게 다른 client가 일부 node만 acquire하는 
현상이 줄어들 수 있다. 

```
for server in self.servers:
    try:
        if self.lock_instance(server, resource, val, ttl):
            n += 1
    except RedisError as e:
        redis_errors.append(e)
```

##### check validity time, quorum

majority의 lock aquire를 하지 못했으면 바로 unlock을 한다.

```
validity = int(ttl - elapsed_time - drift)
    if validity > 0 and n >= self.quorum:
        if redis_errors:
            raise MultipleRedlockException(redis_errors)
        return Lock(validity, resource, val)
    else:
        for server in self.servers:
            try:
                self.unlock_instance(server, resource, val)
            except:
                pass
```

#### Unlock

```
def unlock(self, lock):
    redis_errors = []
    for server in self.servers:
        try:
            self.unlock_instance(server, lock.resource, lock.key)
        except RedisError as e:
            redis_errors.append(e)
    if redis_errors:
        raise MultipleRedlockException(redis_errors)
```

### 문제점

5개의 독립적인 Master node들이 있는데, Client가 이중에 3개만 성공적으로 Set을 하고 lock을 acquire했다고 하자.
그런데 Set을 성공한 3개의 node중에 하나가 restart되어서 key값이 없어지면, 다른 client가 다시 3개의 node에 set을
할 수 있게 된다. 그럼 두개의 client가 lock acquire할 수 있게 되버린다.

이러한 상황을 방지하기 위해서 두 가지 방법을 설명하고 있다.

1. AOF persistence을 enable해서 node가 restart 되었을 때, 데이터를 복구하도록 한다. 
fsync는 default로 1초에 한번씩 disk에 저장하게 되는데, 모든 command에 대해서 disk에 저장하도록 변경하여
node가 restart되었을 때, key를 잃지 않도록 할 수 있다.
2. AOF persistence는 performance에 영향을 미치고, node가 물리적 이상으로 shutdown되면 AOF persistence도 소용이 없다.
그래서 AOF를 enable하지 않고 node가 restart될 때 TTL 이후에 restart될 수 있도록 delay를 하는 방법을 사용할 수 있다.
근데 이 방법도 majority의 node가 문제가 생겨 restart되면 TTL동안은 distribute lock system이 작동되지 못할 수 있다. 