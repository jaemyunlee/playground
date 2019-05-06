import argparse
from datetime import datetime
import uuid
import time

import boto3

parser = argparse.ArgumentParser(description='Test dynamoDB')
parser.add_argument('--create-table', type=int, choices=[0,1], default=0)
parser.add_argument('--set-data', type=int, choices=[0,1], default=0)
parser.add_argument('--query', type=int, choices=[0,1], default=0)
create_table = parser.parse_args().create_table
set_data = parser.parse_args().set_data
query = parser.parse_args().query

client = boto3.client('dynamodb', region_name='ap-northeast-2')


def create_batch_item(vote_type):
    result = []
    for _ in range(25):
        result.append(
            {
                'PutRequest': {
                    'Item': {
                        "user_id": {"S": uuid.uuid4().hex},
                        "vote_for": {"S": vote_type},
                        "vote_time": {"S": datetime.utcnow().isoformat()}
                    }
                }
            }
            # item size: 82 bytes
            # 6 bytes + 32 bytes + 8 bytes + 1 btyes + 9 bytes + 26 bytes
        )

    return result

def get_total(vote_type):
    response = client.query(
        TableName='vote-c1',
        IndexName='vote-case1-index',
        Select='COUNT',
        KeyConditionExpression='#v=:vote_type',
        ExpressionAttributeNames={
            '#v': 'vote_for'
        },
        ExpressionAttributeValues={
            ':vote_type': {'S': vote_type}
        },
        ReturnConsumedCapacity='INDEXES'
    )

    print(response)
    num = response['Count']

    if response.get('LastEvaluatedKey'):
        response = client.query(
            TableName='vote-c1',
            IndexName='vote-case1-index',
            Select='COUNT',
            KeyConditionExpression='#v=:vote_type',
            ExpressionAttributeNames={
                '#v': 'vote_for'
            },
            ExpressionAttributeValues={
                ':vote_type': {'S': 'A'}
            },
            ReturnConsumedCapacity='INDEXES',
            ExclusiveStartKey=response.get('LastEvaluatedKey')
        )

        print(response)
        num += response['Count']

    return num

if create_table:
    response = client.create_table(
        TableName='vote-c1',
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
            },
            {
                'AttributeName': 'vote_for',
                'AttributeType': 'S'
            }
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'vote-case1-index',
                'KeySchema': [
                    {
                        'AttributeName': 'vote_for',
                        'KeyType': 'HASH',
                    }
                ],
                'Projection': {
                    'ProjectionType': 'ALL'
                }
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    print(response)

if set_data:
    # 82 bytes item
    # expected query up to 1MB / 82 = 12195 Items at once
    # create 12175 Items with A vote type
    for _ in range(487):
        response = client.batch_write_item(
            RequestItems={
                'vote-c1': create_batch_item('A')
            },
            ReturnConsumedCapacity='TOTAL'
        )

        print(response)

    time.sleep(2)

    # create 10000 Items with B vote type
    for _ in range(400):
        response = client.batch_write_item(
            RequestItems={
                'vote-c1': create_batch_item('B')
            },
            ReturnConsumedCapacity='TOTAL'
        )

        print(response)

if query:
    a_total = get_total('A')
    b_total = get_total('B')

    print(f'total: {a_total + b_total}, A: {a_total}, B: {b_total}')

