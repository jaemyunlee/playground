# 목차

KEYS command가 Redis server의 CPU utilization을 엄청나게 사용한다는 것을 알게 되었다. Redis의 Item이 몇 백만개가 있는 상황에서 생각없이 KEYS command를 사용했다가는 엄청난 CPU utilization 사용과 장시간(몇 초) blocking이 발생할 수 있다. 그래서 Redis & AWS Elasticache에 대해서 시간을 가지고 더 공부하고 생각해보았다.

[1. Redis is single threaded?](#redis-is-single-threaded)

[2. Scary KEYS command?](#Scary-KEYS-command)

[3. KEYS 대신에 SCAN?](#keys-대신에-scan)

[4. What's new in Elasticache Redis 4.0 and 5.0?](#whats-new-in-elasticache-redis-40-and-50)

[5. Re:Invent 2018 Elasticache Deep Dive 강연 참고하기](#reinvent-2018-elasticache-deep-dive-강연-참고하기)

# Redis is single threaded?

Redis는 한 redis server가 100,000 QPS정도를 처리할 수 있고, Pipeline을 사용하게 되면 1,000,000 QPS를 처리할 수 있을 정도로 빠르다. 보통 Redis에서 CPU가 bottleneck이 되기보다는 Memory나 Network가 bottleneck이 된다. 

Redis와 호환되는 AWS Elasticache에서 Cloudwatch metric으로 CPU utilization과 Engine CPU utilization이 제공된다. Redis는 Single process에서 대부분 single thread로 돌아가기 때문에, 하나의 redis server가 multi thread로 multi core를 활용할 수 없다. 그래서 4vCPU 이상의 node에서는 Engine CPU utilization Metric을 제공한다. [CPU Cores and Threads Per CPU Core Per Instance Type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-optimize-cpu.html)를 보면 m5 type instance에서 4vCPU부터 CPU core가 2개 이상이 된다. r5 type instance도 4vCPU부터 CPU core가 2개이다. Redis server가 사용하는 CPU metric은 하나의 core로 생각해서 파악해야 된다.

CPU power를 더 활용하려면 결국은 sharding을 해서 여러개의 노드(프로세스)가 독립적으로 작동할 수 있도록 해야 한다. Elastiache는 Cluster mode를 enable해서 이러한 sharding을 해줄 수 있다. 구글링을 해보면 Redis도 mutli thread로 하나의 redis server 자체의 성능을 향상시켜야 된다는 의견을 쉽게 볼 수 있다. Redis를 fork해서 multi threading으로 성능을 향상시켰다는 [KeyDB](https://github.com/JohnSully/KeyDB)도 있다. single thread에서는 어떠한 한 command가 오래 걸린다면 이 command가 전체를 blocking하게 되는 큰 단점이 있다. multi-threading을 하게 되면 thread safety 이슈 때문에 locking이 필요하고 설계가 더 복잡해지는 부분이 있다. 오히려 이러한 locking mechanism이 잘 못 설계되면 성능이 떨어질 수도 있는데, multi threading 이슈는 흥미로운 주제인 것 같다. (Python에서도 GIL이 있기 때문에)

redis 4.0에서는 module API와 UNLINK command로 다른 thread를 더 활용하게 되었다. Module이 다른 thread에서 별도로 작동이 되고 redis data에 접근해야 할 때만 module API로 global lock을 aqauire하고 release할 수 있게 되었다. [Redis module중 하나인 RediSearch](https://oss.redislabs.com/redisearch/Threading.html)에서 간단히 잘 설명하고 있다. 큰 데이터를 삭제할 때 DEL은 single thread에서 blocking 요소가 될 수 있는데, UNLINK는 먼저 keyspace해서 해당 key를 지워서 main thread에서는 접근할 수가 없게 하고, 다른 thread에서 memory를 reclaming한다. [그럼 DEL은 언제 필요할까?](http://www.odbms.org/2018/03/the-little-known-feature-of-redis-4-0-that-will-speed-up-your-applications/) UNLINK는 바로 memory space를 비우는게 아니기 때문에, 뭔가 바로바로 memory space를 비워줘야 하는 상황에서는 DEL이 적합할 수 있다.

# Scary KEYS command

KEYS사용에 있어서 [Redis 문서](https://redis.io/commands/keys)에서 친절하게 경고하고 있다.

> Warning: consider KEYS as a command that should only be used in production environments with extreme care. It may ruin performance when it is executed against large databases. This command is intended for debugging and special operations, such as changing your keyspace layout. Don't use KEYS in your regular application code. If you're looking for a way to find keys in a subset of your keyspace, consider using SCAN or sets.

아주 특별히 관심을 가지고 아주 특별한 경우에 사용해야 하는 기능인 것을 알 수 있다. 몇 백만개의 item이 있는 redis에서 KEYS를 사용하게 되면 아주 쉽게 Engine CPU utilization(Elasticache Metric)이 크게 올라가는 것을 볼 수 있다. 그리고 redis-cli로 Elastiache node에 접속해서 `slowlog get 10`를 확인해보면 몇 초가 걸리는 걸 확인 할 수 있다. Redis에서 몇 초는 엄청나게 긴 시간이고, main thread에서 이 작업 때문에 전체가 blocking되고 있다는 의미이다. 어플리케이션에서 이렇게 KEYS를 사용하는 패턴이 일상적으로 사용된다면 아주 쉽게 Redis server를 먹통으로 만들 수 있는 것이다.

# KEYS 대신에 SCAN?

SCAN은 cursor based iterator이다. 한번에 다 작업해서 key들을 가져 오는 것이 아니라, 일정 영역의 key들을 가지고 오고 그다음에 updated cursor값으로 다음 영역의 key들을 가져온다. SCAN에도 MATCH option이 있어서 pattern에 일치하는 key들 가져 올 수 있다.

```
127.0.0.1:6379> set key1 key1
OK
127.0.0.1:6379> set key2 key2
OK
127.0.0.1:6379> set non2 non2
OK
127.0.0.1:6379> keys *
1) "key2"
2) "non2"
3) "key1"
127.0.0.1:6379> scan 0 match key* count 1
1) "2"
2) 1) "key2"
127.0.0.1:6379> scan 2 match key* count 1
1) "1"
2) (empty list or set)
127.0.0.1:6379> scan 3 match key* count 1
1) "0"
2) 1) "key1"
```

COUNT option은 한번에 얼마나 많은 영역에서 key들을 찾을지 설정하는 것이다. 위에서는 dataset이 적기 때문에 COUNT option을 1로 지정해서 테스트하였다. COUNT option의 default는 10이기 때문에, 위의 예제에서는 한번의 작업으로 key들을 다 가져 올 수 있다.

```
127.0.0.1:6379> scan 0 match key*
1) "0"
2) 1) "key2"
   2) "key1"
```

이렇게 SCAN을 사용하면 KEYS처럼 장시간동안 blocking하지 않고 key들을 iteration하면서 가져올 수 있다. 하지만 SCAN은 이렇게 cursor와 함께 iteration하면서 가져오기 때문에, iteration 과정에서 변경되는 값들이 반영이 될 수도 있고 안될 수도 있다. 그리고 중복된 값을 얻을 수도 있다. 

중복되는 값을 받을 수도 있다? 

Redis에서는 key들의 크기에 맞춰서 hash table를 가지고 있는데, hash table이 가질 수 있는 key 갯수보다 더 많은 key가 필요하게 되면 크기를 늘려서 rehashing작업이 진행된다. 예를 들어 처음에 네개의 bucket(key를 담는 공간)이 있었다고 하면, 이제 이 bucket을 두배로 늘려서 여덟 개로 늘린다. 그리고 이제 key들을 8개의 bucket에 rehashing하게 되는 것이다. 그리고 이 bucket은 linked list로 구성되어 있다. (hash funcion의 collision 문제를 linked list방식으로 해결한 것이겠지?) 이렇게 linked list의 길이가 길어지면 hash table에서 O(1)로 접근하더라도 다시 길이만큼 검색을 해야 되는 문제가 발생한다. 그래서 Redis에서는 이 길이가 어느 ratio를 넘어가게 되면 rehashing작업이 시작된다. Redis에서 이렇게 bucket 숫자가 늘어나고 rehash되는 작업이 한번에 다 이루어지기 않고 bucket하나씩 순차적으로 진행이 된다.

hashing되는 과정에서 SCAN을 하게 되면 기존의 bucket과 새로운 bucket을 같이 검색하게 되는데, 이 과정에서 중복 데이터를 얻을 수도 있게 되는 것이다. 그래서 SCAN으로 어떤 작업을 설계할 때, 이러한 중복되는 데이터가 발생될 수 있다는 점을 감안해야 한다.

# What's new in Elasticache Redis 4.0 and 5.0?

AWS Elasticache가 Redis 4.0과 5.0을 지원하면서 올린 자료를 확인해보았다. Module은 Elasticache에서 사용이 불가능하다.

[Elasticache Redis 4.0](https://aws.amazon.com/blogs/aws/new-redis-4-0-compatibility-in-amazon-elasticache/)

- LRU cache eviction policy
- Asynchronous FLUSHDB, FLUSHALL, UNLINK
- Active memory defragmentation
- Online Cluster Resizing and Encryption in transit
- MEMORY commands

[Elasticache Redis 5.0](https://aws.amazon.com/redis/Whats_New_Redis5/)

- Streams
- Sorted sets
- Redis Modules (AWS Elasticache doesn't support this)

vCPU is a hyperthread of an Intel Xeon core

# Re:Invent 2018 Elasticache Deep Dive 강연 참고하기

[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/QxcB53mL_oA/0.jpg)](http://www.youtube.com/watch?v=QxcB53mL_oA)

## Time Series in Redis before Redis 5

Redis 5의 Stream 이전에는 SortedSet으로 score를 Unix time으로 해서 만들 수 있었다. 하지만 이 방법은 Value가 unique해야 되고 score의 Unix time이 mutable하다는 점이 단점이다. 그리고 List로도 할 수 있겠는데, 이제 consumer가 blocking command로 pop해서 가져가는 방식이라 fanout capability에서 단점을 보이고 이제 pop해서 정상적으로 처리못했을 때 message recovery에서 문제점이 있다. Pub/Sub 방식으로 설계할 때는 Channel을 통해서 subscriber에게 전달하여 fanout문제를 해결할 수 있지만, 데이터가 data structure로 persistent하게 있지 않기 때문에 채널을 listening하지 않으면 message를 잃게 된다.

Redis 5의 Stream은 immutable하고 fanout only인 stream에 producer가 msg를 XADD하면 consumer가 Item을 listening하거나 query할 수 있다. Consumer groups이라는 기능도 있다.

## M5 / R5

다음 세대인 M5, R5가 performance가 당연히 좋을 것이다. 아직도 M4, R4 인스턴스 타임을 쓰고 있다면 M5, R5로 사용하는 것을 고려해봐야겠다.

## Comming soon

Performance boost for multi-core nodes
Further optimization providing significant throughput boost

Rename command support
Ability to rename a command

Self-service patching
provides increaed flexibility to control when updates occur

## Redis use cases

- caching
- Real-time analytics
- Gaming leaderboards
- Geospatial
- Media streaming
- Session store
- Chat apps
- Message queues
- Machine learning

> We typically see as caching becomes mabye the second most common use case and People start using Redis whether it be a buffer behind adjusting data fast ... or maybe they want to do a leaderboard...

## Redis cluster enabled

Configuration Endpoint을 통해서 어떤 shard로 가야할지 알 수 있다. Failover에서 Cluster enabled Elasticache에서는 DNS update가 필요가 없기 때문에 DNS propagation이 필요한 cluster disabled elasticache보다 빠르다.

shard 숫자를 변경해도 zero downtime이다. Cludwatch Metric과 SNS Topic을 통해서 Lambda를 trigger해서 shard를 조절할 수도 있겠다.

## Caching - GET/SET ResultSets as Hash

Caching을 할 때 Redis string type으로만 대부분 한 것 같다. string type말고 다른 data structure를 활용할 수 있는지 생각해봐야겠다.

## Redis max-memory policies

volatile-lru는 expire set이 설정된 keys부터 eviction이 될 수 있도록 설정할 수 있다. eviction도 어떻게 될지 전략을 세울 수 있겠다.