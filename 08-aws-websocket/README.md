# AWS websocket gateway

Re:Invent 2018에서 websocket이 소개되고 나서 간단하게 테스트해봤는데, 2월달에 Cloudformation에도 websocket이 추가되었다.

DynamoDB stream을 받아서 Websocket으로 전달하는 간단한 예제를 만들어보았다.

## Websocket limit

- New connections per second per account (across all WebSocket APIs) per region: 500
- Connection duration for Websocket API: 2 hours
- Idle Connection Timeout: 10 minutes 

## Example

`VoteTable`에 atomic counter로 vote_sum attribute의 숫자를 UpdateItem으로 증가시키면,
DynamoDB stream을 통해서 lambda를 Invoke한다. 이 Lambda에서 websocket으로 client에게 count 숫자를 보낸다.

### sam deploy

after creating s3 bucket

`bash deploy.sh`

### websocket 연결

`wscat -c wss://<websocket endpoint>`

### updateItem

after setup first Item in VoteTable

`update-item.sh`