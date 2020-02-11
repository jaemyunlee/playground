# Keep learning project #2 : k8s <!-- omit in toc -->

I played around with Minikube and EKS to understand Kubernetes. I would like to be a kind of expert about Kubernetes. My journey to be an expert about Kubernetes just started!

## History <!-- omit in toc -->

- [Vitess: Sharded MySQL on Kubernetes](#vitess-sharded-mysql-on-kubernetes)
- [Kubernetes Operators Explained](#kubernetes-operators-explained)
- [KubeCon 2018 Keynote: Maturing Kubernetes Operators - Rob Szumski](#kubecon-2018-keynote-maturing-kubernetes-operators---rob-szumski)
- [KubeCon 2018 Kubernetes Design Principles: Understand the Why - Saad Ali, Google](#kubecon-2018-kubernetes-design-principles-understand-the-why---saad-ali-google)

## [Vitess: Sharded MySQL on Kubernetes](https://youtu.be/E6H4bgJ3Z6c)

🤔 Youtube에서 사용하였고 Borg때부터 stateless app으로 적용되어 k8s에 바로 활용 될 수 있었구나!
🤔 이 영상에서는 Kubernetes위에서 MySQL를 Vitess로 운영하는 것을 설명했는데, major adoptor인 Slack은 2019 최근 Kubecon에서 아직 Kubernetes위에 운영하지 않고 EC2위에 운영하고 있다고 했다. 그리고 다른 우선순위가 있어서 계속 EC2에 migration을 한다고 했다.
🤔 제일 궁금했던 것이었는데 영상 마지막 Q&A시간에 질문이 있었다. Vitess가 AWS MySQL과 비교해서 장점을 물었는데, 제한 없이 scale이 가능하고 instance size를 선택할 필요없이 더 딱 맞는 사이즈를 운영할 수 있고, 마지막으로 가장 중요하게 AWS에 갇혀 있지 않고 migration를 할 수 있는 장점이 있다고 설명한다. Vitess를 보면서 Kubernetes를 진짜 멋있게 쓰려면 Database도 Kubernetes에 올리고 특정 Cloud service vendor에 갖히지 않고 비교적 쉽게 migration할 수 있을 것이라 생각했는데, 이 영상에서 그 부분을 다시 한번 강하게 때린 것 같다.
🤔 Demo에서 Materialized view를 생성하여서 활용하는 것을 보여줬다. Vitess로 쉽게 Materialized view를 생성하네? MySQL에서 내부적으로 쉽게 Materialized view를 생성할 수 있는 방법이 있는건가?
🤔 mysql proxy가 postgresql proxy는 sharding되어 있는 경우 unified view를 제공하여 aggregation을 해주나?

> If you instead use a storage that is provided by the cloud like RDS, then migration out of that is a lot harder. Whereas if you are 100% on kubernetes it is so easy to move.

What is Vitess
- Sharding middleware for MySQL
- Massively scalable
- HA
- Cloud-native

Key adopters
- Slack
- Square
- Pinterest

Architecture

vtgate가 stateless app server로 client로부터의 query request를 받는다.
vttablet이 개별적으로 mysql instance를 실행하고 관리한다. vttablet이 뜨면 이제 topology에 스스로 등록하고 vtgate가 discovery한다.

stateful set가 하나의 instance만 master로 지정하는 것을 허용하지 않기 때문에 이제 pod type를 master와 slave로 구분해서 만들어야 한다. 그런데 이제 master가 shut down되면 이제 slave로 설정되어 있던 것을 pod type를 바꿔서 master로 승격 시킬 수가 없기 때문에 master pod가 다시 실행되어서 traffic을 받을 때가지 기다려야 된다. 이 방법은 HA에 적합하지 않다. 그래서 vtgate가 master를 체크해서 문제가 있으면 이제 replica로 스위칭해서 작업을 완료하고 클라이언트는 에러를 리턴 받는게 아니라 1~2초 latency가 늘어나는 것을 겪게 된다.

MySQL 같은 데이터베이스에서 로컬 스토리지를 쓰는 것이 성능상 유리하다. Kubernetes에서는 이제 pod를 shut down하면 data를 다 지우게 된다. 보통 EBS나 Container Storage Interface base의 storage를 붙여서 사용하게 되는데, local pv 기능은 제한이 있어서 아직 프로덕션에서 많이 활용되지 못하는 것 같다. Vitess architecture에서는 pod가 shutdown되면 이제 backup으로 부터 restore하고 그다음에 catch up을 한다음에 트래픽을 다시 받게 된다. semisynchronous replication feature을 이용해서 slave에서 ack를 받아야 하도록 해서 replica에 transaction이 보관된 것을 보장할 수 있다. master와 replica가 동시에 다 shoutdown되지 않으면 이제 data loss는 방지하게 된다.

Vitess에서 다음과 같은 기능들을 통해서 장점을 가져갈 수 있다.
1. main db 하나 있을 때
   - Connection pooling
   - Deadlines
   - Hot row protection
   - Row count limit
2. Master & replicas
   - Replica routing
   - Load balancing
   - Master promotion with Orchestrator
3. Shards
   - Unified view
   - Sharding agnostics

## [Kubernetes Operators Explained](https://youtu.be/i9V4oCa5f9I)

😉 Operator는 이제 Abstraction해서 client가 single YAML file로 create하면 Operator가 받아서 복잡한 요소들을 만들어 줄 수 있구나.

Control loop
- Observe
- Diff
- Act

Controller acts on that for every default resource

In cluster, you need
- Operator Lifecycle Manager
- Operator

Two major components of operator
- CRD
- Controller

## [KubeCon 2018 Keynote: Maturing Kubernetes Operators - Rob Szumski](https://youtu.be/kld1Fi8RrRQ)

🤔 Database를 k8s위에서 제공하는 것이 startup에서도 가능할까?
- Community에서 만든 Operator를 사용하여 MySQL이나 Redis를 k8s위에 올려서 사용하기 쉬울까? stable하고 안전할까?

Kubernetes adoption phases
1. Stateless apps
   - ReplicaSets
   - Deployments
2. Stateful apps
   - StatefulSets
   - Storage/CSI
3. Distributed systems
   - Data rebalancing
   - Autoscaling
   - Seamless upgrades

Operator framework
- Operator SDK: build
- Operator Lifecycle manager: run 
- Operator metering: operate

## [KubeCon 2018 Kubernetes Design Principles: Understand the Why - Saad Ali, Google](https://youtu.be/ZuIQurh_kDk)

😙 Kubernetes의 주요 Principle들을 이해할 수 있었다.
- imperative 대신에 declarative로 구성하였을 때 어떤 장점이 있는지?
- 왜 각 component들이 API server를 watch하여 작동하는지?
- hidden internal API없이 Kubernetes의 모든 component들이 같은 API를 사용함으로써 커스텀하게 component 직접 구성하여 대체하거나 확장하는 것이 유리해지는 것.
- secret, config map등에서 data를 fetch할 때 왜 file이나 Environment variable로 application이 가져오는지?
- remote storage를 설정할 때 PersistentVolume과 PersistentVolumeClaim으로 Abstraction을 어떻게 하는지?
- pod, node object도 day 0에서는 CRD(Custom Resource Definition)의 중 하나라는 것의 의미.

Kubernetes Principles
- Kube API declarative over imperative
- No hidden internal APIs
- Meet the user where they are
- Workload portability