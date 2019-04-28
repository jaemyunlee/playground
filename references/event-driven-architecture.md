# learning from conferences

## [GOTO 2017 The Many Meanings of Event-Driven Architecture](https://youtu.be/STKCRSUsyP0)

Event-driven이랑 관련된 4가지 pattern
- Event notification
  - Decouple receiver from sender ✅
  - No statement of overall behvaior ❌
- Event-carried State Transfer
  - decouling ✅
  - reduced load on supplier ✅
  - replicated data -> eventual consistency ❌
- Event Sourcing
  - Audit ✅
  - Debugging ✅ 
  - HIstoric State ✅
  - Alternative State ✅
  - Memory Image ✅
  - unfamiliar ❌
  - external systems ❌
  - event schema ❌
  - Identifiers ❌
  - versioning ❌
- CQRS

Event notification이 제일 흔한 패턴인데, producer와 consumer를 decoupling 해주지만, event가 시스템 전체에 어떤 영향을 미치지는 파악하기 힘들어진다.
Event notification에서 event가 발생되서 전달되면 consumer가 더 많은 정보를 얻으려고 producer에 다시 가야 될 수도 있다.
이벤트에 필요한 정보를 실어보내서 이러한 트래픽을 줄 일 수는 있지만, 여러가지 상황에서 producer에서 더 많은 정보를 가져와야 되는 경우가 발생할 수 있다.
아주 드문 경우지만 Event-carried State Transfer 패턴으로 consumer가 필요한 데이터를 copy해서 가지고 있도록 할 수 있다.
Producer service data가 변경되었을 때 broadcast되어서 consumer service에 전달이 되어야 한다. 
Event-carried State Transfer 패턴은 이러한 load를 줄일 수 있지만 replicate data하는 복잡성을 가져오고 Eventual consistency가 된다.
Event Sourcing의 장점중에 Memory Image가 있는데, 한 회사 예를 든다. 
어플리케이션은 state에 대한 정보를 memory에 가지고 있고 DB transaction등이 필요없이 빠르게 작동할 수 있게 구성되었다.
매일밤마다 이제 snapshot을 만들고 혹시나 장애가 발생하면 다시 state를 rebuild한다.
이벤트 스트리밍에서 계속 persistent storage에 저장되면서 어플리케이션에 state change되고,
혹시나 문제가 생기면 이 persistent storage로부터 state rebuild를 빨리 하는 거겠지.

- 🤔이렇게 memroy Image 특징을 살려서 하려면 Lambda 같은 걸로 만들 수는 없겠다.
- 🤔여전히 event notification 패턴을 적용했을 때, 다른 서비스 개발자들이 공유할 수 있는 documentation은 어떻게 하는게 좋을까???

--- 

## [Design Microservice Architectures the Right Way](https://youtu.be/j6ow-UemzBc)

### Qcon London 2018

발표자인 Michael Bryzek는 Gilt에서 공동창업자 및 CTO로 일하고 Gilt를 팔고 flow라는 회사에서 공동창업자 및 CTO로 일하는 사람.
Gilt에서 400개의 마이크로 서비스가 운영되고 있었다고 한다.
스칼라를 사용하고 play framework를 사용한다.

Microservice의 misconception을 설명하면서 Polyglot이 얼마나 expensive한 접근지 말하고 code generation이 안 좋은 것만은 아니라고 말한다.
Flow에서는 code generation을 많이 사용하고, Scala, PosgreSQL로 어느정도 제한하고 있는 것처럼 보인다.

#### code generation

Flow에서는 API first 운영방식으로 먼저 API resource를 정의하고 별도의 API를 전체를 위한 리포에서 Integration test를 진행한다.
그리고 이것을 바탕으로 code generation을 하게 된다.

code generation
- Routes
- Clients
- Mock Client

Database로 cli로 필요한 것을 만든다. metadata로 정의하면 table schema를 만든다.


#### deployment

- deploy triggered by a git tag
- git tags created automatically by a change on master (e.g merge PR)
- 100% automated, 100% reliable


#### Event

내부의 모든 네트워크 통신은 API가 아니라 event로 통신하게 된다.
synchronous API 통신이 정말로 필요한 예외 경우만 API를 사용하게 한다.

- First class schema for all events
- Producers guarantee at least once delivery
- Consumers implement idempotency

postgresql record create되면 publish to kinesis 그리고 downstream으로 전해져서 action이 취해진다,

##### producer & consumer process

producer입장에서는 journal에 등록된 걸 kinesis에 publish. replay는 journal를 바탕으로 다시 requeue.

consumer 입장에서 kinesis가 event를 local storage에 저장한다. 
event가 어플리케이션에 도착하면 record를 queue에 보내서 처리되게 한다.
batch로 incoming events를 주기적으로 처리한다. default를 250ms

#### update dependencies

- 🤔 API first 전략으로 하니깐 API resource정보와 코드가 Sync가 맞을 수밖에 없겠다.
- 🤔 Mock Client도 자동으로 만들고 이걸로 integration test를 하는구나.
- 🤔 First class schema for all events. 
우리도 서비스별로 Event schema를 정의하고 그걸 바탕으로 Event producing이랑 consumed하는 부분 테스트를 쉽게 짤 수 있도록 해야겠다.
- 🤔 kinesis에서 event를 local storage에 저장하는데 SNS ffƒFTopic에서 모든 event에 대해서 lambda trigger해서 DB저장하는 거랑 같네.
- 🤔 우리도 dependencies version도 관리할 수 있는 tool과 문화를 만들면 좋겠다.
- 🤔 이렇게 automation으로 test가 통과하면 continous deployment할 수 있는 걸 만들고 싶다