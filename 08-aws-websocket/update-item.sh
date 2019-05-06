aws dynamodb update-item \
--table-name vote-table \
--key '{"vote_for": {"S":"A"}}' \
--update-expression "SET vote_sum = vote_sum + :incr" \
--expression-attribute-values '{":incr":{"N":"1"}}' \
--region ap-northeast-2