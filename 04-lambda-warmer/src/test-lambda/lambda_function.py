import json
from warmer import warmer_handler
import time

from datetime import datetime
from functools import wraps

msg = {
    'warmer': True,
    'concurrency': 0,
    'delay': 100
}

@warmer_handler
def lambda_handler(event, context):
    time.sleep(1)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }