# Re:Invent 2019

Re:Invent를 처음으로 직접 현장에서 볼 수 있는 기회가 생겼다. 5일 동안 Re:Invent에 65,000여명의 사람이 참석하고, 2,500여개의 세션이 열렀다. 외국에서 처음 참석해보는 컨퍼런스였는데, 내가 상상했던 것보다 훨씬 큰 규모의 행사였다. 세션이 열리는 호텔 주위로 AWS Re:Invent 후드티를 입은 사람들이 엄청 많았다. 오늘 나는 이런 큰 규모의 컨퍼런스에서 느낀 점과 경험을 기록하려고 한다.

## Keynotes

keynote에서 가장 인상 깊었던 것은 아직 IT market 97%가 아직 on-premises에 있고, 단지 3%만 Cloud에 있다는 설명이었다. 나는 스타트업에서 커리어를 시작해서 Cloud환경이 익숙해졌고, 네트워킹도 cloud service들을 적극적으로 활용하는 기업의 사람들과 이루어져왔다. 그래서 오직 3%만 클라우드가 차지한다는 것이 놀라웠다. Re:Invent기간 동안 몇 명의 Data engineering분들을 만나게 되었는데, 그들의 회사는 이제 조금씩 클라우드 서비스를 도입하고 있다고 하였다. 아직 Enterprise급의 큰 회사는, 특히 금융권은 아직도 많은 회사들이 on-premises에서 운영되고 있다는 걸을 다시 한번 깨달았다. 이렇게 많은 회사가 on-premises 혹은 Hybrid로 운영하는 경우가 많을텐데, 그래서 AWS에서 Outpost를 만들어서 제공하는 것 아닐까 생각이 들었다.

Andy Jassy의 키노트에서 소개된 새로운 서비스들 중에서 Sagemaker와 Machine learning관련 서비스들이 가장 큰 비중을 차지한 것 같다. `AI is the new normal`이 되어 가고 있는 시대에서 당연한 것 같다. 

### Day1: Monday Night Live with Peter DeSantis

- HPC(High Performance Computing) workload를 처리할 수 있는 Supercomuter를 Cloud에서 Elastic하게 제공할 수 있다. (placement group network, nitro controller and custom network stack)
- Machine learning system을 운영할 때 90% 요금을 차지하는 추론(Inference)을 위한 chip인 Inferentia를 AWS에서 design하였다.
- 전 세계의 AWS network communication이 100%가 encrypt된다.
- 직접 태양광발전과 풍력발전을 통해서 재생에너지를 생산하는 프로젝트를 운영하고 있고, 2040년까지 net zero carbon을 달성하겠다.

### Day2: Keynote with Andy Jassy

- Reinventing the hypervisor with the AWS Nitro system, AWS에서 design한 Arm based graviton2를 이용한 M6g, R6g, C6g
- EKS fargate, S3 access point, AQUA(redshift query cache), managed cassandra service, sagemaker studio, godeguru, outpost 정식출시, Local zone, 5G wavelength

### Day4: Keynote with Dr. Werner Vogels

- Nitro System 설명
- MicroVM인 Firecracker가 Fargate에 적용되었고, high scale과 high density를 위해서 각 MicroVM에 있는 Fargate data plane을 bare metal instance에서 동작하도록 개발하고 있다. (각 MicroVM이 Fargate data plane이 실행될 동안 기다리지 않아도 되기 때문에 더 빠르게 Fargate instance가 실행 될 수 있다. [re:invent 2018 AWS Lambda Under Hood](https://youtu.be/QdzV04T_kec?t=1653)에서 Firecracker가 잠깐 소개되었다.)
- cell-based architecture로 blast radius를 줄였다. (EBS는 Physalia라는 이름의 tiny database로 구성되어 blast radius가 더욱 작아진다.)
- 복잡한 물류 시스템, amazon echo, amazon go에서 IoT device, machine learning등을 통해서 혁신을 해왔다. Industry 4.0 시대에서 많은 고객들이 AWS를 통해서 혁신하고 있다.

## Hackathon

나는 Re:Invent 현장에서만 특별하게 해볼 수 있는 것을 경험하기로 계획했었다. 그래서 Re:Invent 첫날에 진행된 `Non-Profit Hackathon For Good`을 참가했다. 아침 9시부터 오후 6시까지 5명이 팀을 이뤄서 Hackathon이 진행되었다. 해커톤 당일 전날인 일요일 저녁에 해커톤 참가자들과 네트워킹을 하고 팀을 구성하는 시간이 있었다. (나는 일요일 네트워킹 모임에 참가해서 같이 팀을 하자는 사람을 만났지만, 월요일날 그 사람이 다른 사람들과 팀을 따로 구성해서 나도 월요일날 다시 새로운 팀을 찾았다.) 그래서 이미 팀을 구성한 사람도 있었고, 당일날 와서 팀을 구성하는 사람들도 있었다. 나는 행사장에서 만난 Brian, Liang, Brad, Matt와 한 팀이 되어서 해커톤을 시작하였다.

### Hackathon challenges

social 문제를 해결하는 비영리단체를 소개되었고, 각 비영리단체가 나와서 그들이 해결하고자 하는 challenge들을 설명했다. 각각의 팀들은 소개된 네 개의 단체의 challenge중 하나를 선택하여 해결방안을 제시해야 했다.

#### Best Friends Animal Society

Best Friends Animal Society is seeking to reunite pets lost during a disaster with their families with the
help of SNIF (Saving Noses is Fundamental), a new platform that you will help build. SNIF should be a
mobile-friendly application that makes pet-family reunification possible by empowering pet owners
and rescuers to create and access data-rich profiles about cherished animals. SNIF should be easy to
use, especially in a high-stress disaster scenario, and built using a constellation of advanced techniques
including artificial intelligence, machine learning, and data analytics.

#### SkyTruth

SkyTruth hopes to stop pollution in the ocean so marine ecosystems and coastal communities can
thrive. Your challenge is to build the key components of a platform that will monitor the whole ocean,
all the time, and empower citizens, law enforcement, NGOs, and even retailers to work in unison to
bring polluters to justice. You can choose to either build models that reliably detect oil slicks at sea and
identify the polluters; demonstrate a global-scale data analytics infrastructure using their data;
or design engaging interfaces that make everyone an ocean warrior.

#### Urban Institute

The Urban Institute is hoping to create affordable housing roadmaps for cities struggling with
displacement and gentrification. Unfortunately, they lack the foundational data needed on the kinds of
buildings in different cities. They need a dataset that will allow research organizations and cities to
create data-driven, affordable housing plans, monitor neighborhood change, and possibly create early
warning systems for gentrification and displacement. We challenge you to create a generalizable
methodology that takes satellite, LIDAR, and building footprint data input and outputs predicted
building heights.

#### Vibrant Emotional Health

To help Vibrant Emotional Health, your challenge is to develop a service that builds personalized
safety plans for people calling the Lifeline. Safety plans empower callers to identify when they may be
at risk, how to cope, and how to get help whenever they need it. This service will allow counselors to
easily create the plan in real-time with the caller and give the person calling the Lifeline an engaging
tool that they can reference and customize independently. This service should provide access to a
safety plan and resources without requiring contact information.

### Hackathon 우리 팀의 아이디어

작년 AWS re:invent의 Hackathon에 참석해본 경험이 있는 Brian이 faciliator역할로 리딩을 하였다. 먼저 네 가지의 challenge들 중에 어떤 것들 선택할지 토론이 있었다. 처음에는 우리 팀원중에 Machine learning에 대한 전문성을 가진 사람이 없었기 때문에 Vigrant Emotional Health를 선택하는 것이 바람직하다는 의견이 많았다. 하지만 접근하기가 쉬운만큼 많은 팀들이 선택할 것 같고 좀 더 도전적인 주제를 선택하기로 하면서 최종적으로 Urban Institute을 선택하게 되었다.

우리는 Footprint와 LIDAR 데이터를 간단한 web page에 올리면 PostgreSQL에 데이터를 저장하고 종합된 데이터로 보고서를 출력해주는 시스템을 만들기로 결정하였다.

Liang이 Urban Institute에서 제공한 데이터들을 Postgresql geopoint 데이터를 저장하는 역할을 맡았고, Matt은 Urban Institute에서 제공한 데이터들을 Json형식으로 parsing하고 테스트하는 역할을 하였다. Brad는 Cloudformation으로 producer, consumer 역할을 하는 EC2 instance와 autoscaling등을 구성하였다. 나는 처음에는 LIDAR 데이터로 height를 계산하는 수학식들을 찾다가 나중에는 footprint와 LIDAR 데이터를 올릴 수 있는 간단한 웹페이지를 만들게 되었다. brian은 발표자료를 준비하고 전체적인 팀관리를 하였다.

### Hackathon 결과

6시가 되어서 모든 팀들이 발표자료와 기타 참고자료를 해커톤 페이지에 올리면서 개발 프로세스는 완료가 되었다. 6시부터는 심사위원 앞에서 3분짜리 발표를 하였다. 심사위원이 선발한 네 개의 팀은 최종 라운드에서 5분짜리 발표를 할 수 있게 되었다. 아쉽게도 우리는 최종 라운드에 올라가지 못했고 네 개의 팀들의 아이디어와 데모 발표를 감상하였다.

Best Friends Animal Society를 선택한 팀은 모바일 앱에서 사진 올려서 image recognition(sagemaker)로 비슷한 강아지 결과를 앱에서 보여주는 데모를 했다. SkyTruth는 이미지 변환, 간단한 backend API 결과 값 가져오는 데모를 했는데, 가장 완성도가 떨어졌다. Urban Institute는 mapbox위에 footprint data를 얹어서 보여주고 sagemaker로 학습시켜서 Height를 계산해서 보여준다는 데모를 하였다. 마지막으로 Vibrant Emotional Health는 전화받은 사람이 사용할 수 있는 UI page를 만들고, 직접 모바일 앱으로 전화를 걸고 응답하는 데모를 했다.

최종 순위는 Vibrant Emotional Health를 선택한 팀이 1등을 하였고, 그다음으로는 Best Friends Animal Society, Urban Institute, SkyTruth 순으로 순위가 정해졌다.

### 느낌 점

팀에서 나 혼자 비영어권 출신이었다. 짧은 시간동안 결과물을 만들어야 되는 상황이었기 때문에 서로 영어로 빠르게 말해서 따라잡기 힘들었고, 90%는 이해가 되는데 100% 이해가 안되었을 때 팀원들에게 재차 물어보기가 어려웠다. 이러한 분위기에 초반에는 압도되었는데 그래도 그러한 상황에서 내가 할 수 있는 것들을 찾고 끝까지 포기하지 않고 해커톤을 마무리하였다. 아직 내가 해외에서 일할려면 영어가 장벽이 될 수 있다라는 것을 다시 느꼈다.

팀원 중에는 300명 이상의 개발자들이 구성되어 있는 프로젝트에서 devops engineer로 리딩하는 사람도 있었고, 7년동안 LOL를 개발한 회사에서 일한 사람도 있었다. 원래 같이 팀을 하기로 했던 사람도 십년 넘게 C++, C#를 사용하고 AWS는 5년간 사용해온 경력이 많은 개발자였다. 이렇게 해커톤에 참가한 사람들중에 나보다 많은 개발경력을 가진 사람들이 있었다. 하지만 팀들의 결과물들을 보면 생각보다 평범했다. 해커톤이라는 것이 나뿐만 아니라 나보다 경력이 많은 개발자에게도 쉽지 않는 도전이라는 생각이 들었고, 나도 그들사이에서 충분히 좋은 결과물을 만들어낼 수 있다는 자신감을 얻었다. 내년에 또 Re:Invent를 참석할 기회가 된다면 다시 한번 해커톤을 참가하고 더 좋은 결과물을 만들어내고 싶다.

## Sessions

나는 serverless와 devops topic의 세션들을 집중적으로 들었다. 내가 일하는 회사에서 생각해볼 수 있는 세션들이 제일 기억에 남았다.

### Integration test는 어떻게 했어요?

MSA를 운영하면서 어떻게 하면 Integration test를 잘 할 수 있을까 항상 고민하고 있다. 그래서 이번 세션을 듣고 발표자에게 찾아가서 Integration test를 어떻게 하고 있는 여러 번 물어보았다.

`Amazon's approach to high-availability deployment` 세션에서는 preprod stage에서 service를 테스트할 때 dependent가 있는 서비스는 production service와 연결되어서 진행이 된다고 설명하였다. 발표가 끝나고 많은 사람들이 발표자에게 와서 질문을 했는데, 한 사람이 production service에 직접 연결해서 테스트하는 것에 부담이 있고 그리고 POST와 같은 것들을 어떻게 하는지 질문을 했다. 발표자는 가짜 유저로 테스트를 하기도 하고, dependency가 있는 resource들을 복제해서 테스트하기도 한다고 답변했다.

`Moving to event-driven architectures` 세션에서도 발표가 끝나고 발표자에게 찾아가서 질문을 했는데, event-driven architecture에서 integration test는 어떻게 잘 할 수 있는지 질문했다. 좋은 질문이라고 하면서 결론은 직접 이벤트를 consume하는 서비스에서 처리를 정상적으로 하는지 테스트해봐야한다는 답변을 해줬다.

`Atlassian's journey to cloud-native architecture` 세션에서도 발표가 끝나고 또 발표자에게 가서 integration test는 어떻게 하는지 질문했고, integration test로 모든 dependency를 100% coverage할 수 없다고 했다.

Hackathon에서 300명의 개발자가 포함되어 있는 project의 devops lead engineer를 하고 있는 친구에게도 integration test를 어떻게 하는지 물어보았다. 특히 messaging system처럼 async하게 communication할 때는 디버깅이나 테스트하기 더 까다로울텐데 어떻게 서비스간의 integration test를 하는지 물어봤다. 이 친구는 MSA에서 Integration test가 어렵지라고 하면서, 서비스간의 contract를 break하지 않도록 하고 이를 테스트 한다고 했다.

AWS를 사용하면서 DynamoDB의 일부분이 SSL certificate가 업데이트 안되어서 1시간 동안 일부 장애가 있었고, Aurora에서 general query를 사용함에 있어서 bug가 있어서 람다에서 cloudwatch에 보내지 못하고 Aurora storage에 계속 쌓여서 out of disk로 장애가 발생하기도 하였다. 물론 엄청난 규모의 서비스를 운영하면서 이정도의 장애는 별거 아닐 수 있지만, AWS로 사람들이 개발하는 곳이라는 것을 느낀 적이 있었다. (뭔가 인간적인 느낌이 들었다.🤣🤣)

MSA에서 canary deployment로 실제 production traffic에서도 검증을 하는 것과 문제가 생겼을 때 빨리 rollback하고 원인을 찾아서 수정하는 것이 중요하다는 것을 다시 생각해보는 기회가 되었다.

### Event schema

`Moving to event-driven architectures`에서 AWS도 직관적이지 않은 Event schema를 고민하고 있다고 했다. CNCF의 serverless working group에서 진행하고 있는 Cloudevents의 specfication 도입등도 고려하고 있다고 한다.

event schema를 변경하거나 하면 이 event를 사용하고 있는 서비스에서 장애들이 발생할 수 있다. EventBridge 서비스에서 schema registry기능이 소개되었다. schema를 정의해서 registry에 등록하면 discovery를 통해서 IDE 환경에서도 자동완성을 할 수 있고 다양한 language로 validation과 parsing(?)을 해줄 수 있다. schema registry를 우리 개발 환경에 도입할 수 있는지 확인해봐야겠다.

### serverless

serverless관련 세션을 들으면서 여러 기업이 serverless architecture를 도입한 사례들을 듣게 되었다. Keynote에서 많은 Enterprise에서 serverless를 빠르게 도입하고 있다는 이야기를 했다. 내가 만들어 보고 싶은 application을 serverless로 빠르게 만드는 side project를 해봐야겠다는 생각을 했다. 한편으로는 이렇게 serverless로 관리포인트를 줄이면서 빠르게 application을 만들 수 있다는 것은 그 만큼 진입장벽도 낮아지는 것이고, 나의 전문성과 차별성을 어떻게 가져갈 수 있을지 계속 고민이 된다.