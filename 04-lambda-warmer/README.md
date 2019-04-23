# Lambda warmer

Lambda에서 Container의 상태를 확인하고 request를 사용가능한 container에 스케쥴링하는 Worker manager가 있고,
Client의 code를 실행할 수 있는 환경을 Provision하는 Worker가 있다.

Lambda에 invoke request가 오면 Worker manager가 Worker가 있는지 확인하고 해당 Worker에 sandbox를 만든다.
(사용가능한 Worker가 없으면 placement service로부터 worker를 배정받는 과정이 추가된다.)
code를 download하고 runtime을 initialize하고 handler이외의 Client code들이 실행된다.
이렇게 Sandbox가 만들어지는 시간이 cold start 시간이 된다. 이런 Cold start에서 개발자가 optimization할 수 있는 것은 Lambda에서 실행되는 코드의 크기를 줄이거나,
runtime이 Bootstrap되는 부분에서 개선이다. Cold start의 optimization은 AWS에게 많은 부분을 의존할 수 밖에 없다.

이러한 Cold start에서 VPC를 사용하게 되면 ENI를 Lambda worker에 attach해야 된다. 
이렇게 ENI를 설정하는 작업이 로드가 걸니는 작업이라서 VPC lambda cold start는 상당이 오래 걸린다.
작년 re:Invent에서는 remote NAT와 tunelling을 통해서 multi-tenant가 ENI를 사용하는 방식으로
이러한 문제를 개선하려고 한다고 했다. 그래서 Lambda best practice guide에서도 VPC를 반드시 사용해야 되지 않으면 
VPC를 사용하지 말라고 제안을 하고 있다.

하지만, VPC안에 있는 RDS, ElasticCache, Private subnet에 있는 서비스들과 통신하려고 VPC설정이 된 Lambda를 
사용할 수 밖에 없었다. Cold start로 적게는 7초에서 많게는 십몇초까지 걸리는 문제를 해결할 필요가 있었다.
따라서 Lambda를 warm하게 유지하는 작업을 추가하게 되었다.

## warmer

여러가지 reference를 검색하면서 [lambda-warmer](https://github.com/jeremydaly/lambda-warmer)를 찾게 되었고, 
이 아이디어를 가져와서 warmer를 만들게 되었다.

이 아이디어는 Cloudwatch event rule로 warm하고 싶은 람다를 5분(no VPC)이나 15분(VPC) 간격으로 Invoke하게 된다.
concurrent하게 invoke가 되는 만큼 람다를 warm하기 위해서 원하는 concurrency 만큼 lambda를 async하게 invoke한다.
마지막에는 Invoke방식을 Sync로 설정하여 response를 받고 끝낸다. For loop으로 Promise를 만드는 로직에서
Lambda memory default size 124MB에서 1024MB로 올려서 어느 정도 optimization해야 했다.

### warmer하는 Lambda 
```javascript
const AWS = require('aws-sdk');
const lambda = new AWS.Lambda({apiVersion: '2015-03-31'});

exports.handler = async (event) => {
    const { functionName, concurrency, delay } = event;
    const param = {
            FunctionName: functionName,
            InvocationType: "Event",
            Payload: new Buffer(JSON.stringify({
                'warmer': true,
                'delay': delay
            }))
        };
    let invoke_list = [];

    for (let i=1; i<concurrency; i++) {
        invoke_list.push(lambda.invoke(param).promise())
    }
    const start = Date.now()
    Promise.all(invoke_list).then((res) => {
      console.log(`elpased time : ${Date.now() - start}ms`);
      console.log("It completes invoking all lambdas asynchronously.")
    })

    let result = await lambda.invoke({
        FunctionName: functionName,
        InvocationType: "RequestResponse",
        Payload: new Buffer(JSON.stringify({
            'warmer': true,
            'delay': delay
        }))
    }).promise();

    return result
};
``` 

### client decorator

서비스들은 Python으로 개발되어 있기 때문에 decorator를 만들어서 warmer가 Invoke한 거면
logic들이 실행되지 않고 delay만 하고 return하게 만들었다.
이 delay는 얼마나 currency하게 lambda를 warm시킬 것인가에 따라서 tuning이 되어야 할 필요가 있다.
200개를 warm 시킨다고 하면 200개 모두가 기존 warm된 lambda를 다시 invoke하지 않도록 10개를 warm할 때보다 더 많은 delay시간을 줘야했다.

😓 Python, AsyncIO 😓

warm시키는 lambda를 처음에는 Python으로 만들려고 했었다. aiobotocore를 사용하려고 했으나, supported AWS services로
S3, DynamoDB, SNS, SQS, Cloudformation, Kinesis만 있었다. 그래서 태생이 event loop에서 돌아가는 node로 만들었다.

```python
import os
import json
import time

from datetime import datetime
from functools import wraps


def warmer_handler(f):
    """
    Event msg format should be like this
    msg = {
        'warmer': True,
        'concurrency': 0,
        'delay': 100
    }
    """
    @wraps(f)
    def wrapper(*args, **kwargs):
        if args:
            event = args[0]
            print(f"event : {json.dumps(event)}")
            if event.get('warmer'):
                current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                lambda_name = os.getenv('AWS_LAMBDA_FUNCTION_NAME')
                stream_name = os.getenv('AWS_LAMBDA_LOG_STREAM_NAME')
                print(f"WARMER : {lambda_name} {stream_name} get warmed up at {current_time}")
                time.sleep(event.get('delay', 0.3))
                return
            return f(*args, **kwargs)
        return wrapper
```

### concurrency 확인

#### ConcurrentExecutions Metric

Cloudwatch Metric에서 Lambda 전체에 대한 종합 metric를 제공한다. 
테스트 환경에서 다른 Lambda가 invoke되고 있는 상황이 아니였기 때문에, 이 metric max값으로
요청한 N만큼 Concurrent하게 람다가 실행되었는지 검증하는데 사용했다.

#### Cloudwatch insight query

Lambda가 Concurrent하게 실행될 때 각 람다마다 log stream을 독립적으로 가져간다고 생각된다.
따라서 Cloudwatch insight에서 아래와 같이 stream name별로 counting을 해서 확인을 해보았다.
😓 Cloudwatch logs에 안 들어가는 경우도 있기 때문에 정확한 Invoke 갯수가 아닐 수도 있다..

```
filter service == 'warmer' |
stats count_distinct(stream_name) by bin(15m)
```

### Client response time 측정

간단하게 Cold start가 발생하는 것만 체크하기 위해서 Python script를 작성하였다.
Lambda를 Invoke하는 API gateway endpoint를 POST하는 Task를 N개만큼 만들어서 asyncio gather로 
동시에 Hit하도록 하였다. warm된 Lambda로부터 response time과 cold start labmda로부터 response time를
구분만 할려는 목적으로 만들었다.

```python
import argparse
import multiprocessing
import os
import time

import aiohttp
import asyncio


def worker(concurrency_target):
    async def fetch(session, url):
        async with session.post(url) as response:
            res = await response.text()
            endtime = time.time()
            print(f"approx elapsed time : {endtime-starttime}")
            return res

    async def run(session, num):
        url = os.environ['URL']
        tasks = []
        for _ in range(num):
            task = asyncio.ensure_future(fetch(session, url))
            tasks.append(task)
        responses = asyncio.gather(*tasks)
        global starttime
        starttime = time.time()
        await responses

    async def main():
        conn = aiohttp.TCPConnector(force_close=True)
        async with aiohttp.ClientSession(connector=conn) as session:
            await run(session, concurrency_target)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="set currency number")
    parser.add_argument('concurrency', metavar='N', type=int, help='an integer for setting cucurrency')
    args = parser.parse_args()
    concurrency_target = args.concurrency
    threads = 6
    worker_load = []
    remainder = concurrency_target % threads
    load = int(concurrency_target / threads)

    if remainder:
        worker_load = [load] * (threads - 1)
        worker_load.append(load + remainder)
    else:
        worker_load = [load] * threads

    for load in worker_load:
        p = multiprocessing.Process(target=worker, args=(load,))
        p.start()
```

### 테스트 결과

```
python measure-response-time/main.py 100
```

100개의 lambda가 concurrent하게 invoke되는 target으로 잡고 테스트하였다. 
warmer-lambda에서 test-lambda를 concurrent하게 100개 invoke를 15분 간격으로 하고,
위의 코드로 100개를 동시다발적으로 API gateway에 request 요청을 하였다. 
정상적으로 cold start없이 response가 온다.

VPC의 cold start에서 ENI가 제일 큰 병목이다. 그래서 Worker는 존재하고 sandbox가 존재하지 않을 경우에는
cold start가 길지 않다. worker가 없어서 placement service에 요청해서 새로운 worker를 할당받고 여기에 
새롭게 ENI를 설정할 때 큰 병목이 생긴다.

위의 measure-repsone-time python script의 currency arg를 늘려가면서 실행하면,
Subnet의 사용 가능한 IPv4 숫자가 줄어드는 것을 확인 할 수 있다. 그리고 이렇게 ENI가 새로운 private IP를 부여받을 때,
VPC lambda의 cold start가 발생한다. worker가 새로 배치되지 않고 기존 worker에 sandbox를 추가로 생성하는 경우에는 빠르게
실행되는 것을 판단된다.

## 생각

- 🤔 VPC를 꼭 사용해야 람다일 경우, 설계시 더욱 더 신중하게 고려해야 되겠다. 빠른 response가 필요한 상황에서 VPC가 없는 lambda도
cold start가 이슈가 되는데, VPC 설정된 Lambda는 cold start가 심각하다. warmer로 어느정도 예측되는 트래픽 패턴에서는 미리 N개의 Lambda를
concurrent하게 띄어 놓는 방법으로 해결이 될 수 있다. 하지만 여전히 예상보다 더 많은 traffic이 몰리면 그 이상의 traffic에서는 Cold start들이 발생할 수 밖에 없다. 
그렇다고 미리 엄청난 양의 람다를 계속 Invoke에서 유지하는 것은 비효율적이고 낭비이다. 

## reference
- [AWS re:Invent 2018 AWS Lambda under the hood](https://youtu.be/QdzV04T_kec) 
- [Lambda Wamer Jeremy's blog](https://www.jeremydaly.com/lambda-warmer-optimize-aws-lambda-function-cold-starts/)