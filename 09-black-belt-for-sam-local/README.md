# AWS SAM local test

It explains how to use SAM local command to test your python lambda in your local machine.
This example covers AWS resources below.

- API gateway & custom authorizer
- SQS
- DynamoDB
- Lambda

There are five example lambdas.

- authrozier
    - custom authroizer for API gateway
- lambda1
    - purpose: test endpoint to get a item from DynamoDB
    - path: /one/
- lambda2
    - purpose: test endpoint to put a item into DynamoDB and send a message to SQS
    - path: /two/
- lambda3
    - purpose: test endpoint to recieve message from SQS
    - path: /three/
- lambda4
    - purpose: to invoke lambda
    - path: It doesn't integrate with API gateway resource

you need to install

- docker
- aws sam cli
  - `pip install aws-sam-cli`
    
## step 1 `sam build`

All resources for test are already defined in `template.yml`. 
The version of `boto3` library which is preinstalled in lambda runtime is pretty outdated.
If you want to set DynamoDB with on-demand option, preinstalled `boto3` will raise an error.

[AWS document](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)

|python version|boto3 version|
|---|---|
|Python3.6|boto3-1.7.74 botocore-1.10.74|
|Python3.7|boto3-1.9.42 botocore-1.12.42|
 
That's why I add boto in `requirements.txt` to install recent boto3 library.

you run `sam build` command to install packeges which you add in `requirements.txt`

`$ sam build`

now you can see directory `.aws-sam`. In the directory, there are artifacts which will be deployed when you deploy.

if you need to add c extension library, you should build with -u option.
Because you need build this library for Lambda(Linux) not for your local machine(Mac).

`$ sam build -u`

> -u, --use-container \
If your functions depend on packages that have natively compiled dependencies, use this flag to build your function inside an AWS Lambda-like Docker container.

## step 2 `docker-compose up`

It needs dyanmodb and SQS running locally. So you can create these resource locally with Docker images.

`$ docker-compose up`


```yaml
version: '3'
services:
  dynamodb:
    image: amazon/dynamodb-local
    ports:
      - "3306:3306"
    networks:
      - my_network
    volumes:
      - db-data:/home/dynamodblocal/data
  localstack:
    image: localstack/localstack
    ports:
      - "4567-4584:4567-4584"
      - "8080:8080"
    networks:
      - my_network
    environment:
      - SERVICES=sqs
  dbsetup:
    build: ./setup
    networks:
      - my_network
    depends_on:
      - dynamodb
      - localstack
    command: ["./wait-for-resource.sh"]
    environment:
      - AWS_ACCESS_KEY_ID=foo
      - AWS_SECRET_ACCESS_KEY=bar
      - AWS_DEFAULT_REGION=ap-northeast-2
volumes:
  db-data:
networks:
  my_network:
```

dbsetup needs to run after DynamoDB and SQS being ready for connection.
It takes a few seconds until SQS is ready for this.
That's why I add command `command: ["./wait-for-resource.sh"]` in `docker-compose.yml`. 
I checks If it succeeds to connect to SQS and then creates SQS queue when it is ready.

## step 3 `bash start-api.sh`

You can test api endpoints with `sam local start-api`. 
you created DynamoDB and SQS running locally. Now Lambdas can use those resources.
`--docker-network` option allows to connect in an existing Docker network.
You already made a Docker network with `docker-compose`.

```
$ docker network ls

NETWORK ID          NAME                   DRIVER              SCOPE
5d1174387c6c        example_my_network     bridge              local
```

You have to set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` same value in `docker-compose.yml`.
Because you can't find table which you make with different cridentials. It is defined as foo, bar.
So I injects those credential with same value as Environemnt variables. 

```
# start-api.sh

AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar AWS_DEFAULT_REGION=ap-northeast-2 \
sam local start-api --docker-network=example_my_network
```

Now you can see three endpoints information on your console.
You can request to those endpoints and test locally.

```
2019-05-28 17:00:49 Found credentials in environment variables.
2019-05-28 17:00:49 Mounting LambdaTwo at http://127.0.0.1:3000/two/ [POST]
2019-05-28 17:00:49 Mounting LambdaOne at http://127.0.0.1:3000/one/ [GET]
2019-05-28 17:00:49 Mounting LambdaThree at http://127.0.0.1:3000/three/ [GET]
```


---

## test lambda with event

Actually LambdaFour does poliing SQS queues and should be triggered when there are messages.
`sam local start-api` doesn't mock this. In this situation, you can test the lambda individually.

### create event data

sam also has feature to generate sample event data.

```$ sam local generate-event sqs receive-message > event.json```

### `sam local invoke`

You can test a lambda which should be triggered by SQS polling by passing the event data.
Because It works same except It is triggered automatically when there are messages.

`$ sam local invoke  --event event.json LambdaFour`


## test automation

you also need test automation with test codes. you can reqeuest to endpoints and test with it.

```python
# /test/test-request-api.py

import requests

r = requests.get(url='http://127.0.0.1:3000/one/')
print(r.json())
```

If your lambda is not exposed to API endpoints, you can start lambda and invoke it.

`$ sam local start-lambda`

```python
import boto3
import botocore

lambda_client = boto3.client('lambda',
        aws_access_key_id="foo",
        aws_secret_access_key="bar",
        region_name="ap-northeast-2",
        endpoint_url="http://127.0.0.1:3001/",
        use_ssl=False,
        verify=False,
        config=botocore.client.Config(
            signature_version=botocore.UNSIGNED,
            read_timeout=10,
            retries={'max_attempts': 0},
        )
    )

response = lambda_client.invoke(FunctionName="LambdaFour")

print(response)
```

## test with AWS toolkit(PyCharm)

### Globals is not implemented yet

It seems using AWS toolkit in PyCharm IDE is more convenient(There are AWS toolkit for other IDEs).
But AWS toolkit is preview stage and it doesn't seem stable yet. AWS toolkit in PyCharm has a bug with `Globals` in SAM template. A issue relating to this problem is still open.

[Github Issue: Globals Runtime and Handler raise a java.lang.IllegalArgumentException](https://github.com/aws/aws-toolkit-jetbrains/issues/941)

So if you want to use AWS toolkit with PyCharm, you need to add runtime property in every lambdas even if you already add it in `Globals`.
Other property are not required so It will set to a default value.

```yaml
# template.yml
...
Globals:
  Function:
    Runtime: python3.6
...
LambdaOne:
    Type: "AWS::Serverless::Function"
    Properties:
      FunctionName: !Join ["-", [mmt, !Ref Environment, black, belt, one]]
      Description: get a item from DynamoDB
      Runtime: python3.6 # I add it again
...
```
### It always build new artifacts

When you use `sam local` command, It doesn't build again if there is .aws-sam directory.
It just reuse files which is already built previsouly in .aws-sam.
But when you use PyCharm AWS toolkit, It always build again and store it temp file.

### Step-Through Debugging

The main reason why I want to use IDE was to use debugger with breakpoints. If application code get complicated, I really like to debug with breakpoints.

AWS toolkit keep making errors `java.lang.IllegalArgumentException: can't parse argument number:` and 
a red exclamation mark keep blinking in the bottom right corner. It is little bit annoying But It would be better to use when you need a debugger.

[how to install AWS toolkit on PyCharm](https://docs.aws.amazon.com/toolkit-for-jetbrains/latest/userguide/setup-toolkit.html) 