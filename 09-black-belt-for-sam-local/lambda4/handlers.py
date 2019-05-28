import json

def lambda_handler(event, context):
    print(event)
    
    return {
        "statusCode": 200,
        "body": json.dumps({'msg': 'success to be invoked'})
    }