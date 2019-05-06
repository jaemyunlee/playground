import uuid

import boto3

client = boto3.client('dynamodb', region_name='ap-northeast-2')
user_id = uuid.UUID('6d943bba-6fe2-11e9-a1fe-8c859001af74')

response = client.put_item(
    TableName='vote-c2',
    Item={
            "user_id": {"S": user_id.hex},
            "vote_for": {"S": 'A'},
            "vote_time": {"S":'2019-05-06T09:39:20.527183'}
        },
    ConditionExpression='attribute_not_exists(user_id) and attribute_not_exists(vote_time)'
)
print(response)

"""
{
    "Records": [
        {
            "eventID": "bd9f8a6aa3266e00e0b6366355261fe7",
            "eventName": "INSERT",
            "eventVersion": "1.1",
            "eventSource": "aws:dynamodb",
            "awsRegion": "ap-northeast-2",
            "dynamodb": {
                "ApproximateCreationDateTime": 1557135594,
                "Keys": {
                    "user_id": {
                        "S": "6d943bba6fe211e9a1fe8c859001af74"
                    },
                    "vote_time": {
                        "S": "2019-05-06T09:39:20.527183"
                    }
                },
                "NewImage": {
                    "user_id": {
                        "S": "6d943bba6fe211e9a1fe8c859001af74"
                    },
                    "vote_for": {
                        "S": "A"
                    },
                    "vote_time": {
                        "S": "2019-05-06T09:39:20.527183"
                    }
                },
                "SequenceNumber": "559500000000001367591240",
                "SizeBytes": 157,
                "StreamViewType": "NEW_AND_OLD_IMAGES"
            },
            "eventSourceARN": "arn:aws:dynamodb:ap-northeast-2:*:table/vote-c2/stream/2019-05-06T09:13:52.516"
        }
    ]
}
"""

response = client.update_item(
    TableName='vote-c2',
    Key={
        'user_id': {"S": user_id.hex},
        'vote_time': {"S": '2019-05-06T09:39:20.527183'}
    },
    UpdateExpression='SET vote_for = :vote_type',
    ExpressionAttributeValues={":vote_type": {"S":"AB"}}
)

print(response)

"""
"Records": [
        {
            "eventID": "31c864aa631ca6c028a3e21854e65c1f",
            "eventName": "MODIFY",
            "eventVersion": "1.1",
            "eventSource": "aws:dynamodb",
            "awsRegion": "ap-northeast-2",
            "dynamodb": {
                "ApproximateCreationDateTime": 1557135959,
                "Keys": {
                    "user_id": {
                        "S": "6d943bba6fe211e9a1fe8c859001af74"
                    },
                    "vote_time": {
                        "S": "2019-05-06T09:39:20.527183"
                    }
                },
                "NewImage": {
                    "user_id": {
                        "S": "6d943bba6fe211e9a1fe8c859001af74"
                    },
                    "vote_for": {
                        "S": "AB"
                    },
                    "vote_time": {
                        "S": "2019-05-06T09:39:20.527183"
                    }
                },
                "OldImage": {
                    "user_id": {
                        "S": "6d943bba6fe211e9a1fe8c859001af74"
                    },
                    "vote_for": {
                        "S": "A"
                    },
                    "vote_time": {
                        "S": "2019-05-06T09:39:20.527183"
                    }
                },
                "SequenceNumber": "559600000000001367635017",
                "SizeBytes": 241,
                "StreamViewType": "NEW_AND_OLD_IMAGES"
            },
            "eventSourceARN": "arn:aws:dynamodb:ap-northeast-2:*:table/vote-c2/stream/2019-05-06T09:13:52.516"
        }
    ]
"""