# 문제

ECS의 service들의 Log들을 Cloudwatch log group에 lambda subscribe을 걸어서 Elasticsearch에 보내고 있었다.

ECS service -> Cloudwatch agent -> Cloudwatch log group -> Lambda -> Elasticsearch -> Kibana

ECS service 갯수가 늘어나고 Log량도 많이 늘어나면서 Lambda에서 Bulk Api로 log 정보를 ES에 넣을 때 에러가 발생했다.

# 문제분석

### lambda error log 파악

Lambda에서 Elasticsearch로 Bulk API로 Post할 때, 300번대 이상의 status code가 있으면 failedItems으로 반환하도록 되어 있다.

```javascript
post(elasticsearchBulkData, function(error, success, statusCode, failedItems) {
    console.log('Response: ' + JSON.stringify({
        "statusCode": statusCode
    }));

    if (error) {
        console.log('Error: ' + JSON.stringify(error, null, 2));

        if (failedItems && failedItems.length > 0) {
            console.log("Failed Items: " +
                JSON.stringify(failedItems, null, 2));
        }

        context.fail(JSON.stringify(error));
    } else {
        console.log('Success: ' + JSON.stringify(success));
        context.succeed('Success');
    }
});
```

### query on cloudwath log insight

Cloudwatch log insight에서 해당 Lambda의 로그를 분석해보면, `403`, `429`, `503`이 발생한 것을 알 수 있다.

```
fields index.status
|filter @message like "Failed Items"
|stats count(*) by index.status
```

#### 403

error reason: `blocked by: [FORBIDDEN/8/index write (api)]`

error type: `cluster_block_exception`

#### 429

error reason: `rejected execution of org.elasticsearch.transport.TransportService$7@5441ccaf on EsThreadPoolExecutor[name = xORyT18/bulk, queue capacity = 200, org.elasticsearch.common.util.concurrent.EsThreadPoolExecutor@67976a0c[Running, pool size = 4, active threads = 2, queued tasks = 221, completed tasks = 9337157]]`

error type: `es_rejected_execution_exception`

#### 503

error reason: `failed to process cluster event (put-mapping) within 30s`

error type: `process_cluster_event_timeout_exception`

### lambda timeout

lambda function에서 timeout들도 발생했다.

```
filter @message like "Task timed out after 2.00 seconds"
| stats count(@message) by bin(60min)
```

### bulk queue size & shard 갯수

ECS service별로 log group이 생기고, 이 log group별로 Lambda를 subscribe해서 
log를 Elasticsearch로 보내고 있었다. service별로 index를 log group 이름으로 해서 create하고 있었다.

```javascript
var timestamp = new Date(1 * logEvent.timestamp);
var es_index_name = payload.logGroup.replace(/\//g, "_");

var indexName = [
    'cwl' + es_index_name + '-' + timestamp.getUTCFullYear(), // year
    ('0' + (timestamp.getUTCMonth() + 1)).slice(-2),  // month
    ('0' + timestamp.getUTCDate()).slice(-2)          // day
].join('.');
```

GET _cluster/stats

indices 갯수가 1319개나 있었다. 2주일치의 로그만 보관하고 있는데, 서비스와 환경별로 index를 만드니 이렇게 많은 Index를 유지하고 있었다.

#### queue size 초과: 429

Elasticsearch는 shard마다 single thread로 query가 실행된다.
service별로 index가 만들어지고 거기에 shard가 5개씩이니깐 실행되는 task가 엄청 많았다.
queue size는 200인데, 조금만 traffic이 많아지면 많은 index에서 log ingest를 하면서 queue size를 쉽게 넘어갔다.
그래서 rejected가 되고 `429` 에러가 발생했다.

Cloudwatch Metric에서 ThreadpoolBulkRejected를 보면 확인할수가 있다.

![MetricGraph](https://github.com/jaemyunlee/playground/tree/master/problem-solving/elasticsearch/BulkQueueRejected.png "BulkQueueRejected Metric")

GET /_nodes/nodeId1,nodeId2

```
"bulk" : {
          "type" : "fixed",
          "min" : 4,
          "max" : 4,
          "queue_size" : 200
        },
```

GET /_all/_settings

```
"number_of_shards" : "5",
        "number_of_replicas" : "1",
```

[From Elastic blog](https://www.elastic.co/blog/how-many-shards-should-i-have-in-my-elasticsearch-cluster)
> In Elasticsearch, each query is executed in a single thread per shard. Multiple shards can however be processed in parallel, as can multiple queries and aggregations against the same shard. This means that the minimum query latency, when no caching is involved, will depend on the data, the type of query, as well as the size of the shard. Querying lots of small shards will make the processing per shard faster, but as many more tasks need to be queued up and processed in sequence, it is not necessarily going to be faster than querying a smaller number of larger shards.

이렇게 많은 index와 shards때문에 CPU utilization도 올라가고 cluster state를 heap 메모리에 저장하니깐 memory 사용량도 높았다.

> For each Elasticsearch index, information about mappings and state is stored in the cluster state. This is kept in memory for fast access. Having a large number of indices and shards in a cluster can therefore result in a large cluster state, especially if mappings are large.

> Because the cluster state is loaded into the heap on every node (including the masters), and the amount of heap is directly proportional to the number of indices, fields per index and shards, it is important to also monitor the heap usage on master nodes and make sure they are sized appropriately.

#### ClusterBlockException: 403

[From AWS doc](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-block-disks)
> When the JVMMemoryPressure metric exceeds 92% for 30 minutes, Amazon ES triggers a protection mechanism and blocks all write operations to prevent the cluster from reaching red status. When the protection is on, write operations fail with a ClusterBlockException error, new indices can't be created, and the IndexCreateBlockException error is thrown.

JVM memoery pressure가 92%이상 유지가 오래 되다보니 index create가 아예 block되버리고 `403` 에러가 발생했을 것이다.

#### Indexing latency: lambda timeout

indexing latency metric을 보니깐, peak때는 lambda의 timeout 시간을 넘어갔다.

# 해결

결국은 너무 많은 index와 shard가 문제였다. 그래서 service별로 나뉘었던 index를 하나의 index로 합치도록 수정했다.

---

# 기타

### 비싼 merge 작업

shard는 Lucene index의 instance가 되고, shard에 저장되는 data가 immutable Lucence segment가 disk에 쓰여지면 이제 search가 가능해진다.
이 segment 숫자가 증가하면 segment를 합치는 merge 작업이 발생한다. shard가 많아질 수록 이러한 merge 작업도 증가한다. 

### overhead, small segements

> Small shards result in small segments, which increases overhead. Aim to keep the average shard size between at least a few GB and a few tens of GB. For use-cases with time-based data, it is common to see shards between 20GB and 40GB in size.

### time-based indexing

indexing rate이 일정하지 않고 들쑥날쑥 하다면 rollover index API를 사용하여 일정한 document 갯수가 넘어가면, 
index를 새로 만들도록 할 수 있다.

그리고 여러개의 node에 shard를 균등하게 분배해서 indexing하다가, 이제 더 이상 index에 data를 넣지 않을 때 shrink index api로
shard 사이즈를 적정하게 만드는 것을 고려할 필요가 있다.

### JVM garbage collector

heap에 new object와 old object를 위한 공간을 별도로 가진다. new object에서 collection되고 살아남은 object는 old object공간으로 이동한다.
old object는 garbage collect가 덜 빈번하게 발생한다.

GET _nodes/stats/jvm

young, old의 heap memory 사용량을 알 수가 있다.

m4.xlarge.elasticsearch를 사용해서 16GB memory인데, `"heap_max":"7.9gb"`인 것을 볼 수가 있다.
다른 부분에서도 memory가 사용되기 때문에 JVM heap으로 system의 50% RAM을 할당하는 것이 일반적이다.

[from elastic doc](https://www.elastic.co/guide/en/elasticsearch/reference/master/heap-size.html)

> Set Xmx and Xms to no more than 50% of your physical RAM. Elasticsearch requires memory for purposes other than the JVM heap and it is important to leave space for this. For instance, Elasticsearch uses off-heap buffers for efficient network communication, relies on the operating system’s filesystem cache for efficient access to files, and the JVM itself requires some memory too.

old부분의 메모리 사용량이 75%가 되면 GC가 실행된다.

[from AWS doc](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-block-disks)

> The Concurrent Mark Sweep (CMS) garbage collector triggers when 75% of the “old generation” object space is full. This collector runs alongside other threads to keep pauses to a minimum. If CMS is unable to reclaim enough memory during these normal collections, Elasticsearch triggers a different garbage collection algorithm that halts all threads. Nodes are unresponsive during these stop-the-world collections, which can affect cluster stability.

톱니 모양으로 75%에서 찍고 내려오는 그래프를 보이는 것이 stable한 metric인데, 이전에는 이러한 톱니 모양을 안 보이고 계속 높은 Heap pressure를 보였다.

### Heavy Memory Pressure Consumes CPU

memory pressure가 계속 높으니깐 GC collection이 더 자주 발생하고 CPU utilization도 올라갔을 것이다.
`JVMGCOldCollectionCount` Metric을 보면 CPU, Memory pressure가 높게 유지 될때 같이 높은 count 숫자를 보인다.

![MetricGraph](https://github.com/jaemyunlee/playground/tree/master/problem-solving/elasticsearch/CPUMemoryOldGCCollectionGraph.png "CPU & JVM Heap Pressure & OldGCCollectionCount")

[from elastic blog](https://www.elastic.co/blog/found-understanding-memory-pressure-indicator)

> If the old pool is still above 75% after the collector finishes, the Java virtual machine will schedule a new collection, expecting to finish just before the pool runs out of memory. This means that higher fill rate in the old pool will result in more frequent collections and thus more CPU will be spent on garbage collections as the fill rate approaches 100%.