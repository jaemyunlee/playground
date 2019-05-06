# Total count in DynamoDB

DynamoDB에서 item total count를 어떤 방식으로 할 수 있을지 여러가지 방법을 생각해보고 테스트해보았다.

### 1. Query  

count할 Item이 적다면(count할 Item이 10000개 이하), Query를 이용하여 Item을 Count할 수 있겠다.
Query의 Consumed capacity는 Scan된 Item 전체의 size로 계산된다.

아래처럼 Table을 구성하였다고 가정하자.

Table
- primary key: user_id
- sort key: vote_make
- attribute: vote_for

그럼 vote type별로 query를 할 수 있도록 GSI를 아래처럼 만든다.

GSI
- primary key: vote_for

Item size가 아래처럼 Item을 구성하였을 때는 Item당 82 bytes가 된다.
```
'Item': {
    "user_id": {"S": uuid.uuid4().hex},
    "vote_for": {"S": random.choice(["A", "B"])},
    "vote_time": {"S": datetime.utcnow().isoformat()}
}
```

[AWS document](https://docs.amazonaws.cn/en_us/amazondynamodb/latest/developerguide/Query.html#Query.Pagination)에서
한 번의 query에서 1MB 범위의 result set를 return한다고 나와있다. 따라서 return되는 Item들의 총 size가 1MB 아래이면 pagination없이 한번에 query로 가져올 수 있다고 이해했다.
따라서 82 bytes의 Item을 1MB limit을 고려해서 12175개까지는 한번의 query로 가져올 수 있다고 예상했다.

하지만 `case1.py`로 간단하게 테스트해보니 10382개 이후에 page가 나뉘어졌다. 
Document를 자세히 보니 **1MB in size (or less)** 라고 설명되어 있는 **less**라고 해논걸로 봐서는 정확히 1MB가 아닌 것 같다.

> DynamoDB paginates the results from Query operations. With pagination, the Query results are divided into "pages" of data that are 1 MB in size (or less). An application can process the first page of results, then the second page, and so on.

#### test 결과

##### table 생성

`python case1.py --create-table 1`

##### data setup

`python case1.py --set-data 1`

A vote type으로 12175개의 Item put request \
B vote type으로 10000개의 Item put request

##### query

`python case1.py --query 1`

A vote type는 두개의 page로 나위어졌다. LastEvaluatedKey 존재
- 10382 개
- 1793 개

B vote type는 한번의 query로 모든 Item이 return되었다.
- 10000 개

consumedUnits은 101.5가 찍혔는데, 82 bytes item으로 10000개를 계산하면
`10000*82/4000/2 = 102.5`가 계산되는데 1 RCU차이는 어디에서 나오는지 모르겠다.

### 2. Transaction API

Transaction API를 사용하여서 Table에 user의 vote를 기록하고 동시에 다른 Table에 vote type별 count를 한다.

case 1처럼 table을 구성하면 sum을 위한 table를 하나 더 구성한다.

Table
- primary key: user_id
- sort key: vote_make
- attribute: vote_for

Table for Sum
- primary key: vote_for
- attribute: sum

#### test 결과

##### table 생성

`python case2.py --create-table 1`

##### sum용 item 생성

`python case2.py --set-item 1`

##### transactwrite

`python case2.py --write 1`

sum용 테이블인 vote_sum에 count가 된 것을 확인 할 수 있다.
atomic counter가 적용되었기 때문에 다른 write request와 충돌이 생기지 않는다.
transaction으로 write를 할 때 동시에 같은 Item을 다른 request에서 수정하게 되면 conflict가 발생하게 된다.  

> You can use the UpdateItem operation to implement an atomic counter—a numeric attribute that is incremented, unconditionally, without interfering with other write requests. (All write requests are applied in the order in which they were received.)

```
'Update': {
    'Key': {
        'vote_for': {'S': vote_type}
    },
    'TableName': 'vote-c2-sum',
    'UpdateExpression': 'SET vote_sum = vote_sum + :incr',
    'ExpressionAttributeValues': {':incr': {'N': '1'}}
}
```

### 3. DynamoDB stream & Lambda

세 번째로 DynamoDB stream을 이용하여 Sum을 할 수 있겠다. 
DynamoDB stream enable하고 Lambda trigger를 한다.

StreamViewType
- Keys_only
- new_image
- old_image
- new_and_old_images

PutItem의 경우 INSERT가 되고, UpdateItem의 경우 MOTIFY가 된다.
ConditionExpression에서 PutItem으로 기존 Item이 Override되는 것을 방지하고,
INSERT record에 대해서만 Lambda에서 count up을 해주는 방법으로 구현할 수 있겠다.