import boto3
import botocore

lambda_client = boto3.client('lambda',
        aws_access_key_id="foo",
        aws_secret_access_key="bar",
        region_name="ap-northeast-2",
        endpoint_url="http://127.0.0.1:3001/",
        use_ssl=False,
        verify=False,
        config=botocore.client.Config(
            signature_version=botocore.UNSIGNED,
            read_timeout=10,
            retries={'max_attempts': 0},
        )
    )

response = lambda_client.invoke(FunctionName="LambdaFour")

print(response)