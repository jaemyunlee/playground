# AWS Summit Seoul

## 기조연설

2017년, 2018년에 이어서 이번에 세 번째 AWS Summit Seoul를 오게 되었다. 
기조 연설은 Adrian Cockcroft 클라우드 아키텍터 전략 담당 부사장분이 메인으로 발표를 하였고,
롯데 이커머스와 삼성전자의 VP분들이 어떻게 AWS로 migration했는지 간단한 사례를 설명하였다. 
기조 연설은 data migration, hybrid환경부터, cloud native를 위한 서비스들, ML, AI, Blockchain 등을 다 포괄적으로 설명을 하였다.
많은 내용들이 사실 작년 Summit과 비슷하고 일반적인 내용을 다뤘기 때문에 특별히 흥미로운 점은 없었다.

### 기조연설에서 개인적으로 재미있었던 점은 AWS가 경쟁사(?)를 묘사한 부분들이었다.

#### Azure

발표 자료에서 Microsofts 문구가 나왔는데, Window server가 AWS에서 2배 많게 호스팅되고 있다는 얘기를 한다.
물론, AWS의 market share가 타 cloud provider들보다 월등히 높긴하지만 Azure에게는 좀 굴욕적이지 않을까 생각이 들었다.

#### GCP

Kubernetes를 언급하는 과정에서 대부분의 Kubernetes가 AWS에서 작동하고 있다고 말했다. 
K8S를 Google이 처음 design했었고, AWS보다 먼저 GCP에서 K8S를 잘 지원하고 있었는데, 
AWS에서 대부분(Most kubernetest)이 AWS에서 작동하고 있다고 당당하게 얘기하는게, GCP에게는 굴욕이 아닐까 생각이 들었다.

그리고 Tensorflow를 언급하는 부분에서는 85%의 Cloud-based Tensorflow project가 AWS위에 올라가 있다는 얘기를 하는데, 
K8S 경우와 비슷한 느낌을 받았다. 사실 작년 Reivent:2018에서 GCP의 IaaS market segment가 Alibaba cloud보다 낮다는 점을 알게 되었는데,
충격적이었다.

#### Oracle

몇 달전에 Oracle 회장이 AWS aurora를 엄청 비난하는 [인터뷰 영상](https://youtu.be/xrzMYL901AQ)을 보았었다. 
Co-Founder인 Larry Ellison분이 amazon cloud database에 대한 생각을 얘기하는데, AWS가 oracle database 위에서 돌아가고 있다고 한다.
그리고 그들이 Oracle에서 AWS database로 migration을 못하고 있다고 말한다. Oracle만큼 좋지 않아서...
삼섬전자가 samsung account service를 AWS로 migration하는 사례를 발표할 때, 기존에 Oracle에서 Aurora PostgreSQL로 이전한 사례였다. 
이전하고 성능적으로도 문제가 없었고, 비용절감도 많이 되었다는 얘기를 하는데, Oracle은 AWS가 무섭게 성장하는 것에 대해서 어떻게 대응하고 있는건지 궁금했다.

### Monolithic, MSA에 대한 얘기가 빈번하게 나왔다.

내가 워낙 Microservices architecture에 관심이 많기 때문에 기조연설에서 이 부분이 다른 것보다 상대적으로 
인상에 남았을 수도 있다. 일단 전박적으로 MSA에 대한 언급이 나왔었고, 롯데 이커머스에서 과거 Monolithic한 서비스들이 
MSA로 개편된 이야기, 삼성전자 samsung account 서비스가 monolithic이었는데, 이것도 MSA 형식으로 개편되었다는 이야기가 나왔다.

## MSA
 
Airbnb에서 k8s 환경 구축을 어떻게 했는지 설명한 세션에서 기존 Monolithic에서 MSA로 변경되면서 배포의 숫자가 많이 늘어난 것을 보여줬다. 
베스핀 글로벌스에서 한 세션에서도 MSA architecture가 언급되었다. 

작년 Gartner의 `Hype Cycle for Application Architecture, 2018`을 봤을 때,
Microservices는 `Sliding into the Trough` Phase에 있다고 소개되었다. 
물론 이 Hype graph에 대한 논란은 있지만, 이 Phase를 생각하면 이제 Microservices는 `Slope of Enlightenment`
에 있는 걸까??? 

##### Trough of Disillusionment

> Interest wanes as experiments and implementations fail to deliver.
Producers of the technology shake out or fail. Investment continues only if the surviving
providers imporve their products to the satisfaction of early adopters.


##### slope of Enlightenment

> More instances of how the technology can benefit the enterprise start to crystalize 
and become more widely understood. Second- and third-generation products appear from
technology providers. More enterprise fund pilots; conservative companies remain cautious.

## 아쉬운 점

AWS Seoul summit에 오기 전 여러가지 궁금증이 있었다. 이러한 궁금증을 좀 해소하기 위해서 AWS Expo 부스에 찾아가서 물어보기도 하고, 
발표가 끝난 뒤에 발표자에게 질문들을 했었다. 하지만 아쉽게도 내가 기대한만큼 많은 Insight를 얻어가지 못한것 같다.

- 🤔 MSA를 오랫동안 운영해온 Amazon에서 Domain Driven Design같은 접근방법이 부분적이라도 적용되거나 활용되고 있는 사례가 있는지?
- 🤔 MSA에서 Event-driven 방식이 가져주는 장점에 대해서 설명한 강연들을 많이 봤다. [Flow라는 회사에서는 내부 서비스간 통신은 특별한 경우를 제외하고는 Event로 이루어진다고 했다.](https://youtu.be/j6ow-UemzBc)
Event driven으로 MSA를 구성해서 inter-service communication을 하게 되면 Service mesh를 구성할 의미가 있는 것인가?
- 🤔 Concurrent하게 Lambda를 warm시킬려고 Cloudwatch event rule로 주기적으로 때리고 있는데,
현재 방법에서 불필요하게 500ms나 delay하는 것 같은 생각이 든다.
- 🤔 수백개의 service가 운영되는 회사에서는 어떤 식으로 integration test를 하는지 궁금하다.