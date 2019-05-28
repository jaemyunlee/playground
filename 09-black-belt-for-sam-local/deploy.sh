export ENV=beta
export BUCKET=test

sam build
sam package --s3-bucket ${BUCKET} --s3-prefix ${ENV}/test --output-template-file packaged.yaml
sam deploy --stack-name ${ENV}-test --template-file packaged.yaml \
--parameter-overrides Environment=${ENV} \
--capabilities CAPABILITY_IAM --region ap-northeast-2