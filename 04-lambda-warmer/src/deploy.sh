sam build && sam package --s3-bucket mmt-warmer-test --output-template-file packaged.yaml --region ap-northeast-2 --profile appmesh-test\
&& sam deploy --stack-name warmer-test --template-file packaged.yaml \
--parameter-overrides \
APITraceEnabled=  \
LambdaTraceEnabled=PassThrough \
TestMemorySize=512 \
Delay=0.5 \
Concurrency=10 \
--capabilities CAPABILITY_IAM --region ap-northeast-2 --profile appmesh-test