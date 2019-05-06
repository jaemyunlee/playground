# This example is to demonstrate how dynamoDB calculate item size
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/CapacityUnitCalculations.html

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