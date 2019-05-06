sam build
sam package --s3-bucket test-websocket --output-template-file packaged.yaml
sam deploy --stack-name test-websocket --template-file packaged.yaml --capabilities CAPABILITY_IAM --region ap-northeast-2