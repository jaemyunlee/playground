export ENV=beta

echo endpoint is $(aws cloudformation describe-stacks --stack-name ${ENV}-test \
--query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
--output text --region ap-northeast-2)