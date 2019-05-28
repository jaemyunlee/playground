import json
from log import logger

import boto3

client = boto3.client('dynamodb', endpoint_url='http://dynamodb:8000')

def lambda_handler(event, context):
    response = client.get_item(
        TableName='example',
        Key={'id': {'S':'ABC'}}
    )

    logger.info(response)

    return {
        "statusCode": 200,
        "body": json.dumps({'msg': 'success to get item'})
    }