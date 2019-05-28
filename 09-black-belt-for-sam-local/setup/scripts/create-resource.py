import boto3

dynamodb = boto3.client('dynamodb', endpoint_url='http://dynamodb:8000')
sqs = boto3.client('sqs', endpoint_url='http://localstack:4576/')

response = dynamodb.create_table(
        TableName='example',
        KeySchema=[
            {
                'AttributeName': 'id',
                'KeyType': 'HASH',
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'id',
                'AttributeType': 'S'
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )

print(response)

response = sqs.create_queue(QueueName='exSQS')

print(response)