# DynamoDB item size 계산

[AWS document에서는 item size를 계산하는 방법](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/CapacityUnitCalculations.html)
을 설명하는데, 몇 가지 빠진 설명이 있다.

## test table 생성
```
aws dynamodb create-table \
--attribute-definitions AttributeName=id,AttributeType=S \
--table-name test \
--key-schema AttributeName=id,KeyType=HASH \
--billing-mode PAY_PER_REQUEST \
--region ap-northeast-2
```

## type별 size

### String

(length of attribute name) + (number of UTF-8-encoded bytes)

```
# calculate-item-size.py

attribute_id = 'id' # 2 bytes
id = uuid.uuid4().hex # 32 bytes

attribute_name = 'name' # 4 byte
name = "A" * 900 #  945 bytes
korean = "한글" # 6 bytes
```

UTF-8 encoded byte로 계산하기 때문에 `한글`은 6 bytes가 된다.

### Number

(length of attribute name) + (1 byte per two significant digits) + (1 byte or 2 bytes)

Number type은 최대 38 significant digit를 가질 수 있다.
significant digit는 0이 아닌것은 significant digit이고 0이 아닌 숫자 가운데
있는 0은 significant digit이다. 간단히 생각하면 의미없는 0은 significant digit으로 간주안된다.

0.1000의 significant digit은 1뿐이다.
304는 3, 0, 4 모두 significant digit이다.

significant digit 두개당 1byte로 계산하는데, 여기서 설명안하고 있는 점은 
positive number일 때는 1byte가 추가되고, negative number일 때는 2byte가 추가된다.

```
attribute_num1 = 'num1' # 4 bytes
num1 = "0.123400" # 2 bytes + 1 bytes

attribute_num2 = 'num2' # 4 bytes
num2 = "12345" # 3 bytes + 1 bytes

attribute_num3 = 'num3' # 4 bytes
num3 = "-27" # 1 bytes + 2 bytes
``` 

### Binary

(length of attribute name) + (length of base64 encoded byte)

dynamoDB에서는 binary type의 경우 base64 format으로 encode를 해야 한다.

> A binary value must be encoded in base64 format before it can be sent to DynamoDB, but the value's raw byte length is used for calculating size.

document에서는 이렇게 설명되어 있는데 `하이hi`의 raw byte는 8 bytes이다.
그래서 계산된 size가 8 bytes가 될거라 예상했지만 base64의 character size인 12 bytes로 계산이 된다.

```
attribute_raw = 'raw' # 3 bytes
binary_data = base64.b64encode('하이hi'.encode('utf-8')) # 12 bytes
```

### Map, List

(length of attribute name) + sum (size of nested elements) + (3 bytes) + (1 byte per key value pair or 1 byte per element of list)

String type의 AAA와 BBB는 각 3 bytes가 되고 Number type의 123는 2 byte가 된다.
여기에 element당 1 byte를 추가해야 한다.

attribute name 4 bytes + AAA 3 bytes + BBB 3 bytes + 123 2 bytes + 3 bytes(each element) + 3 bytes(for list type)

```
attribute_list = 'list' # 4 bytes
list_data = [{"S":"AAA"},{"S":"BBB"},{"N":"123"}] # 12 Bytes + 3 bytes
```

map의 경우에는 동일한 방법으로 계산되고 element별 1 byte가 아니라 key value pair당 1 byte를 추가해주면 된다.

```
attribute_map = 'map' # 3 bytes
map_data = {"ABC":{"S":"ABC"}, 'DEF':{"N":"12"}} # 13 Bytes + 3 bytes
```

## 테스트

`calculate-item-size.py`에서 1024 bytes가 계산되도록 item을 조합해서 write request를 하면 consumed capacity가 
1.0인 것을 알 수 있다.

```python
import base64
import uuid

import boto3

client = boto3.client('dynamodb', region_name='ap-northeast-2')

# String: (length of attribute name) + (number of UTF-8-encoded bytes).
attribute_id = 'id' # 2 bytes
id = uuid.uuid4().hex # 32 bytes

attribute_name = 'name' # 4 byte
name = "A" * 900 #  945 bytes
korean = "한글" # 6 bytes

# Number: (length of attribute name) + (1 byte per two significant digits) + (1 byte)
attribute_num1 = 'num1' # 4 bytes
num1 = "0.123400" # 2 bytes + 1 bytes

attribute_num2 = 'num2' # 4 bytes
num2 = "12345" # 3 bytes + 1 bytes

attribute_num3 = 'num3' # 4 bytes
num3 = "-27" # 1 bytes + 2 bytes

# Binary: (length of attribute name) + (number of raw bytes)
attribute_raw = 'raw' # 3 bytes
binary_data = base64.b64encode('하이hi'.encode('utf-8')) # 12 bytes

# Boolean: (length of attribute name) + (1 byte)
attribute_bool = 'bool' # 4 bytes + 1 byte

# List or Map: (length of attribute name) + sum (size of nested elements) + (3 bytes)
attribute_list = 'list' # 4 bytes
list_data = [{"S":"AAA"},{"S":"BBB"},{"N":"123"}] # 12 Bytes + 3 bytes

attribute_map = 'map' # 3 bytes
map_data = {"ABC":{"S":"ABC"}, 'DEF':{"N":"12"}} # 13 Bytes + 3 bytes

item = {
    attribute_id: {"S": id},
    attribute_name: {"S": name + korean},
    attribute_num1: {"N": num1},
    attribute_num2: {"N": num2},
    attribute_num3: {"N": num3},
    attribute_raw: {"B": binary_data},
    attribute_bool: {"BOOL": True},
    attribute_list: {"L": list_data},
    attribute_map: {"M": map_data}
}

response = client.put_item(
    TableName='test',
    Item=item,
    ReturnConsumedCapacity='TOTAL'
)

print(f'Consumed capacity: {response["ConsumedCapacity"]["CapacityUnits"]}')
```

> Item sizes for writes are rounded up to the next 1 KB multiple. For example, writing a 500-byte item consumes the same throughput as writing a 1 KB item.

1025 bytes가 계산되록 `name = "A" * 900`을 `name = "A" * 901`로 바꾸면 consumed capacity가 2.0이 되는 걸 확인할 수 있다.

## write operation별 WCU

1 KB = 1 WCU \
1 KB = 2 WCU for transaction

- PutItem: 동일한 primary key의 item이 이미 있으면 기존의 item을 대체한다. 이때는 UpdateItem처럼 적용된다.
- UpdateItem: 기존의 item과 새로운 item중에 큰 size로 계산
- DeleteItem: delete되는 item의 사이즈
- BatchWriteItem: 개별 write별로 item 사이즈가 계산

## read operation별 RCU

4 KB = 0.5 RCU for eventual consistency \
4 KB = 1 RCU for strong consistency \
4 KB = 2 RCU for transaction

- GetItem 
- BatchGetItem
- Query: Return된 item의 총 size를 합산해서 계산.
- Sacn: evaluated된 item의 총 size를 합산해서 계산.

## Transaction

transaction은 optimistic lock이다. transactionGetItem으로 여러 개의 GetItem을 하는 도중에,
다른 곳에서 해당되는 Item에 PutItem, UpdateItem, DeleteItem, TransactionWriteItem을 하게 되면
conflict가 발생되고 에러가 난다.

