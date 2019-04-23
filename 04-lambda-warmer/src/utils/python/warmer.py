import json
import os
import time

from datetime import datetime
from functools import wraps


def warmer_handler(f):
    """
    Event msg format should be like this
    msg = {
        'warmer': True,
        'concurrency': 0,
        'delay': 100
    }
    """

    @wraps(f)
    def wrapper(*args, **kwargs):
        if args:
            event = args[0]
            if event.get('warmer'):
                current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                lambda_name = os.getenv('AWS_LAMBDA_FUNCTION_NAME')
                stream_name = os.getenv('AWS_LAMBDA_LOG_STREAM_NAME')
                print(json.dumps({
                    "service": "warmer",
                    "lambda_name": lambda_name,
                    "stream_name": stream_name,
                    "invoke_time": current_time
                }))
                time.sleep(event.get('delay', 0.3))
                return
        return f(*args, **kwargs)

    return wrapper
