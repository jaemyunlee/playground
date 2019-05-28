import json
import os
from log import logger

import boto3

dynamodb = boto3.client('dynamodb', endpoint_url='http://dynamodb:8000')
sqs = boto3.client('sqs', endpoint_url='http://localstack:4576/')

def lambda_handler(event, context):
    response = sqs.receive_message(
        QueueUrl=os.environ.get('QUEUE_URL', "http://localhost:4576/queue/exSQS")
    )

    logger.info(response)

    return {
        "statusCode": 200,
        "body": json.dumps({'msg': 'success to get a message'})
    }