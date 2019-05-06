import argparse
from datetime import datetime
import uuid

import boto3

parser = argparse.ArgumentParser(description='Test dynamoDB')
parser.add_argument('--create-table', type=int, choices=[0,1], default=0)
parser.add_argument('--set-item', type=int, choices=[0,1], default=0)
parser.add_argument('--write', type=int, choices=[0,1], default=0)
create_table = parser.parse_args().create_table
set_item = parser.parse_args().set_item
write = parser.parse_args().write

client = boto3.client('dynamodb', region_name='ap-northeast-2')

def transaction(vote_type):
    response = client.transact_write_items(
        TransactItems=[
            {
                'Put': {
                    'Item': {
                        "user_id": {"S": uuid.uuid4().hex},
                        "vote_for": {"S": vote_type},
                        "vote_time": {"S": datetime.utcnow().isoformat()}
                    },
                    'TableName': 'vote-c2',
                    'ConditionExpression': 'attribute_not_exists(user_id)',
                }
            },
            {
                'Update': {
                    'Key': {
                        'vote_for': {'S': vote_type}
                    },
                    'TableName': 'vote-c2-sum',
                    'UpdateExpression': 'SET vote_sum = vote_sum + :incr',
                    'ExpressionAttributeValues': {':incr': {'N': '1'}}
                }
            }
        ],
        ReturnConsumedCapacity="TOTAL"
    )
    print(response)

if create_table:
    response = client.create_table(
        TableName='vote-c2',
        KeySchema=[
            {
                'AttributeName': 'user_id',
                'KeyType': 'HASH',
            },
            {
                'AttributeName': 'vote_time',
                'KeyType': 'RANGE'
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'user_id',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'vote_time',
                'AttributeType': 'S'
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    print(response)

    response = client.create_table(
        TableName='vote-c2-sum',
        KeySchema=[
            {
                'AttributeName': 'vote_for',
                'KeyType': 'HASH',
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'vote_for',
                'AttributeType': 'S'
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    print(response)

if set_item:
    response = client.batch_write_item(
        RequestItems={
            'vote-c2-sum': [
                {
                    'PutRequest': {
                        'Item': {
                            'vote_for': {'S': 'A'},
                            'vote_sum': {'N': '0'}
                        }
                    },
                    'PutRequest': {
                        'Item': {
                            'vote_for': {'S': 'B'},
                            'vote_sum': {'N': '0'}
                        }
                    }
                }
            ]
        }
    )
    print(response)

if write:
    for _ in range(150):
        transaction('A')
    for _ in range(200):
        transaction('B')