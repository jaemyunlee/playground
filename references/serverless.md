# [AWS re:Invent 2018 AWS Lambda under the hood](https://youtu.be/QdzV04T_kec)

## 람다 구성

### control plane
- Developer Tools
  - Lambda console
  - SAM CLI
- Control plane APIs
  - Configuration
  - Resource Mgmt

### Data plane
- Aysnchnronous Invoke & Events
  - Pollers
  - State manager
  - Leasing service

state manager랑 leasing service가 event를 처리해서 synchronouse invoke 영역으로 전달한다.

- Synchronous Invoke
  - Front End Invoke
  - Counting Service
  - Worker Manager
  - Worker
  - Placement Service
  
### Front End Invoke
Orchestrate both synchronous and asynchronous Invokes

### Counting Service
Provides a region wide view of customer concurrency to help enforce set limits

### Worker Manager
Tracks container idel and busy state and schedules incoming invoke requests to available containers

### Worker
Provisions a secoure environment for customer code execution

### Placement Service
Places sandboxes on workers to maximize packing density without impacting customer experience or cold-path latency

## 람다의 flow

### case 1 : with existing worker, needs new sandbox

client => load balancer =invoke=> 
Frontend(authenticate and get metadata and check with counting service)
=Reserve sandboxes=> 
Worker manager(create a sandbox and download code and initialize runtime and run your code)
=> worker 

이렇게 warm sandbox가 만들어지고 나면 worker가 worker manager에게 전달하고,
worker manager가 frontend에 전달해서 이제 frontend가 warm sandbox가 있는 걸 알게 된다.
이제 frontend가 warm sandbox를 invoke한다.
worker가 실행되고 나면 metric이 수집되고 worker manager에게 idle 상태를 전달하게 된다.
warm sandbox가 있다는걸 다시 알게 된다.

### case 2 : with existing worker and existing sandbox

Frontend가 worker manager에게 Reserve a sandbox를 요청하면,
worker manager가 warm sandbox가 있으니깐 이미 있다는걸 Frontend에 알려주고
Frontend가 worker에서 code를 run하게 된다.


### case 3 : needs new worker and new sandbox

위처럼 frontend가 worker manager에게 reserve a sandbox를 하게 되는데,
warm sandbox도 없고 worker도 없다. 그러면 worker manager가 placement service에
claim worker를 한다. placement service가 적절한 worker를 배정해주면 이제 code download하고,
initialize runtime하고 init해서 sandbox를 만든다.

이렇게 placement service가 worker manager한테 worker를 지정해주는데, worker manager의
requests를 잘 처리하기 위해서 6~10시간의 lease time을 가지고 줘서 worker recycling이 될 수 있도록 한다.

이제 worker의 lease time의 만료되는 시점에 가까워지면 worker manager가 그 worker를
돌려주게 된다. 이렇게 만료 시점이 오면 sandbox를 만들지 않고 모든 sandbox가 idle되면,
worker를 돌려준다. 그리고 다시 worker를 배정받아서 provision한다. 

## 2019년에 improve하려는 점

### firecracker

you code\
Lambda runtime\
Sandbox\
Guest OS\
Hypervisor\
Host OS\
Hardware\ 

현재 EC2에 worker가 올라가게 된다. 여러 account가 Hardware와 Host OS를 공유하고,
그위에 Hypervisor로 하나의 account당 EC2처럼 배정이 되고, 그 위에 Container기술과 동일한 방법으로
Lambda를 만들게 된다.

VM에다가 cgroups, namespaces, iptables등 container 기술을 통해서 lambda를 
독립적으로 구성하는게 아니라, firecracker로 micro VM을 만들어서 여러 account가 Hardware와 Host OS를 공유하고,
그 위에 micro VM이 람다를 구성하는 방식으로 개발이 진행되고 있다.

이렇게 firecracker를 사용하면 runtime도 빨라지고, memory도 적게 쓰게 된다.
그리고 일반적으로 Load balancing하면 worker들에게 예르 들어 60% 정도로 로드가 걸리도록 분배하게 된다.
하지만 AWS에서는 람다를 99%까지 사용하고 싶다. 이를 위해서는 다양한 workload를 smart하게 배분하고 싶은데,
이러한 것들이 될려면 충분히 scale이 커야 한다. 여기서는 예를 정규분포를 들었다.
firecracker로 micro VM를 한 lambda당 만들게 되면 통계적인 접근방법으로 이렇게 99%까지 사용하는데 유리하게 되겠다.

### VPC cold start & ENI

VPC에 연결하도록 ENI를 lambda worker에 attach하게 된다.
ENI를 설정하는 작업이 로드가 걸리는 작업이다.

그래서 Lambda와 독립적으로 ENI 앞에 remote NAT를 두고 tunelling을 통해서 multi-tenant가 
ENI를 같이 사용하도록 하고 있다. VPC에 ENI를 attach를 하는 기존 방식은 subnet의 IP 갯수도 고려야하는데,
이러한 부분도 해결 해줄 수 있다.

every single worker is going to consume an IP address from your subnet

# [Introduction to AWS Lambda & Serverless Applications](https://youtu.be/EBSdyoO3goc)

2018년에 이런 것들이 람다에 추가되었구나.

- Go support
- Nodejs V8
- Amazon SQS support
- 15 min execution duration
- 99.95% SLA

## tools

AWS
- SAM
- Amplify
- Chalice

Third-party
- Serverless framework
- Claudia.js
- Zappa
