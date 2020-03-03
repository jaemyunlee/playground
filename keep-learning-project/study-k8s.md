# Keep learning project #2 : k8s <!-- omit in toc -->

I played around with Minikube and EKS to understand Kubernetes. I would like to be a kind of expert about Kubernetes. My journey to be an expert about Kubernetes just started!

## History <!-- omit in toc -->

- [KubeCon 2019 Introduction to CNI, the Container Network Interface Project](#kubecon-2019-introduction-to-cni-the-container-network-interface-project)
- [7 GCP Kubernetes Best Practices videos](#7-gcp-kubernetes-best-practices-videos)
  - [Building small containers](#building-small-containers)
  - [Organizing Kubernetes with Namespace](#organizing-kubernetes-with-namespace)
  - [Kubernetes Health Checks with Readiness and Liveness Probes](#kubernetes-health-checks-with-readiness-and-liveness-probes)
  - [Setting Resource Requests and Limits in Kubernetes](#setting-resource-requests-and-limits-in-kubernetes)
  - [Terminating with Grace](#terminating-with-grace)
  - [Mapping External Services](#mapping-external-services)
  - [Upgrading your Cluster with Zero Downtime](#upgrading-your-cluster-with-zero-downtime)
- [Vitess: Sharded MySQL on Kubernetes](#vitess-sharded-mysql-on-kubernetes)
- [Kubernetes Operators Explained](#kubernetes-operators-explained)
- [KubeCon 2018 Keynote: Maturing Kubernetes Operators - Rob Szumski](#kubecon-2018-keynote-maturing-kubernetes-operators---rob-szumski)
- [KubeCon 2018 Kubernetes Design Principles: Understand the Why - Saad Ali, Google](#kubecon-2018-kubernetes-design-principles-understand-the-why---saad-ali-google)

## [KubeCon 2019 Doing Things Prometheus Can’t Do with Prometheus](https://youtu.be/pRmnh8lgjsU)

발표자는 400 prometheus server를 운영! 와우!

High Availability Prometheus
- Prometheus is not distributed
- Sometimes the network breaks
- Sometimes queries make Prometheus sad
    - 잘못 query를 했다가는 이제 자원을 엄청 쓰고 unresponsive가 될수도

High Availability Prometheus
- thanos-query, promxy fan out to fill gaps
- Decreased query performance
- Big queries fanning out
- Operational overhead

🤔 이 발표에서도 Prometheus는 이제 ditributed하지 않다고 설명하고, HA를 구성하기 위한 방법과 HA에 의한 downside를 설명한다. 

Cardinality

- Every permutation of labels in Prometheus creates a new time series individual queries should use hundreds not thousands of time series 
- Queries that generate on thousands of time series will overload Prometheus 
- Work out your query in the Console before graphing 
- Avoid high cardinality lables

> avoid labels that have unbounded potential values and what the total number of labels that you put on a metric.

🤔 필요 없이 label를 그냥 생각없이 넣다보면 이제 query할 때 몇 천개의 time series에서 가져와야 할 수도 있구나.

실질적으로 하다보면 몇천 time series를 사용하는 query가 생기는데, 발표자는 several thousands 혹은 10,000 이 되어도 크게 문제가 될 것 같지 않다고 하고, 하지만 10,000이 넘어가면 이제 조치를 취해야 함.

Effective Cardinality - protec
Leave resource headroom
--query.max-samples
--query.max-concurrency
shard on logical boundaries or federate

Long-term Metrics Storage
Prometheus 2.8 released disk-backed retention
storage.tsdb.max-block-duration의 값을 이제 5일 이라고 하면 5일 단위로 이제 compact해서 만드는데 이제 disk storage가 부족해서 지우게 되면 이 block단위로 지우게 된다. 

**Mindful data and vanilla Prometheus could be all you need**

Block storage or a fast disk

Separate "long term" server

🤔 Thanos, Promxy, Cortex등을 사용해야 해서 operation 복잡성과 추가적인 비용을 추가해야할 지 고민해봐야 한다. 그냥 Vanila Promethues로도 충분한지 고민해봐야 한다. Promethues 자체가 이제 robust하고 simple하게 만들어졌다고 하는데, HA없이도 충분히 믿을만 한걸까???

Machine learning on Metrics => PromQL has enough features for you to impress your boss

label ephemeral value => Prometheus has an official Go client library that you can use to instrument Go applications.

## [KubeCon 2019 Prometheus Deep Dive](https://youtu.be/Me-kZi4xkEs)

designed to be distributed
- minimal dependencies
  - Local disk
  - Network
- Intentionally un-coordinated distributed system
- Run Prometheus close to your targets
- Vertical sharding before horizontal sharding
  - 1000개 pod가 있는데 500개씩 각각 서비스를 구성한다면 Prometheus를 각각 500씩 그룹에 띄워서.

> Prometheus design was came from a need where the monitoring system needed to be the most reliable thing on the network and which meant that the Prometheus itself needed to have the least number of dependencies on anything else on your network so as long as it's up and running it's got a little local disk and it can reach to the network it can monitor it.

### Q. why do I get float values for increase() when my counter goes up by integers?

Prometheus Metric type
* Counter
* Gauge
* Histogram
* Summary

🤔interpolation을 하는구나. 그리고 scrape도 이제 다른 타이밍에 하더라도 이제 interpolation을 하니깐 상관이 없어지고. 그리고 scape하는데 몇 개 포인트를 못가져와도 이제 전체적으로 정확도가 막 떨어지는게 아니고, total number는 아니깐!

### Q. how much space do I need for Prometheus?

recording rule
Recording rules allow you to precompute frequently needed or computationally expensive expressions and save their result as a new set of time series. Querying the precomputed result will then often be much faster than executing the original expression every time it is needed. This is especially useful for dashboards, which need to query the same expression repeatedly every time they refresh.

Typical formula: 1.5 bytes per sample per second

여기 발표에서는 1700 target이 있고, taget별 700개의 metric을 수집하고, 그리고 15초 주기로 scape을 하고 일부는 5초로 한다. 그리고 많은 recording rules있다고 가정했을 때, 100,000 samples / second * 1.5 bytes * 60 * 60 = 0.5GB/hour

🤔 100,000은 1700*700/15로 하고 이제 5초 scape도 있고 많은 recording rules도 있으니 100,000으로 잡았겠지?

### Q. how do I deal with multiple instances?

horizontal scaling of the data from multiple prometheus instances
* Cortex
* M3DB
* Thanos
* Others

🤔 Federation option도 생각해볼 수 있구나.

Hierarchical federation

Hierarchical federation allows Prometheus to scale to environments with tens of data centers and millions of nodes. In this use case, the federation topology resembles a tree, with higher-level Prometheus servers collecting aggregated time series data from a larger number of subordinated servers.
For example, a setup might consist of many per-datacenter Prometheus servers that collect data in high detail (instance-level drill-down), and a set of global Prometheus servers which collect and store only aggregated data (job-level drill-down) from those local servers. This provides an aggregate global view and detailed local views.

Cross-service federation

In cross-service federation, a Prometheus server of one service is configured to scrape selected data from another service's Prometheus server to enable alerting and queries against both datasets within a single server.
For example, a cluster scheduler running multiple services might expose resource usage information (like memory and CPU usage) about service instances running on the cluster. On the other hand, a service running on that cluster will only expose application-specific service metrics. Often, these two sets of metrics are scraped by separate Prometheus servers. Using federation, the Prometheus server containing service-level metrics may pull in the cluster resource usage metrics about its specific service from the cluster Prometheus, so that both sets of metrics can be used within that server.

### Q. metric에 많은 label를 설정했을 때 storage에 영향이 있는지? 

prometheus inverted index라서 label를 추가하더라도 추가적으로 많은 storage를 차지하지 않는다. value가 많아지면 이제 scan하는데 더 오래 걸리니깐 label할 때 cardinality를 생각해야겠구나! 

### Q. Thanos나 cortex 사용경험에 물어봤다.

발표자는 Thanos를 쓰기 전에는 이제 점점 커지면서 prometheus server가 늘어나기 시작했고, grafana에서 어떤 data source는 이 prometheus server에서 다른 data source는 다른 prometheus server에서 가져와서 이제 이런 데이터를 mixing하는 것 상당히 귀찮은 작업이었다. 그래서 thanos를 overlay proxy로 query를 편리하게 했다. Prometheus server 에 6개월치의 데이터를 보관하는데 Thanos와 잘 작동했다. 

### Q. Thanos query가 느릴 수가 있는데 cache layer를 쓰는지? 

cortex cache layer가 thanos에 merge 되어서 사용가능하다

### Q. alert manager에서 이제 ops팀에서 쉽게 사용할 수 있게 PromQL처럼 코드로 하는게 아니라 뭔가 integration 할 계획이 있는지? 

GUI grafana에게 요청하고 있다. Prometheus팀에서 할 계획이 없다.

🤔 [Jsonnet library](https://grafana.com/blog/2020/02/26/how-to-configure-grafana-as-code/)로 Grafana도 code로 찍어 낼 수 있나보구나!

## [KubeCon 2019 Introduction to CNI, the Container Network Interface Project](https://youtu.be/YjjrQiJOyME)

"CNI was created as a common interface that could be used by any container runtime and and network."

Runtime이 CNI를 Call하는데 이제 ADD로 call하면 이제 Network interface를 컨테이너에 추가한다. 

The CNI project has two major parts
1. The CNI specification documents
2. A set of reference and example plugins

Specification
1. A vendor-neutral specification - not just for Kubernetes
2. Also used by Mesos, CloudFoundry, podman, CRI-O
3. Defines a basic execution flow & configuration format for network operations
4. Attempts to keep things simple and backwards compatible

Configuration Format
1. JSON-based configuration
2. Both standard keys and plugin-specific ones
3. Configuration fed to plugin on stdin for each operation
4. Stored on-disk or by the runtime

Execution Flow
1. Basic commands: ADD, DEL, CHECK and VERSION
2. Plugins are executables
3. Spawned by the runtime when network operations are desired
4. Fed JSON configuration via stdin
5. Also fed container-specific data via stdin
6. Report structured result via stdout

Kubernetes의 경우 이제 Kubelet이 CNI plugin을 separate program을 실행하고 이제 JSON configuration이 컨테이너 데이터를 stdin으로 넣고 이제 결과를 stdout으로 response하면 Kubelet이 받아간다.

> The CNI plugin is selected by passing Kubelet the --network-plugin=cni command-line option. Kubelet reads a file from --cni-conf-dir (default /etc/cni/net.d) and uses the CNI configuration from that file to set up each pod’s network. The CNI configuration file must match the CNI specification, and any required CNI plugins referenced by the configuration must be present in --cni-bin-dir (default /opt/cni/bin). 
[kubernetes document](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni)

[Kubernetes-the-hard-way-aws](https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/09-bootstrapping-kubernetes-workers.md)에서 CNI Networking을 설정하는 것을 보면 kubelet option으로 `--network-plugin=cni` 정의한 것을 확인 할 수 있다. 그리고 `https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz`를 다운 받아서 `/opt/cni/bin/` 경로에 압축을 풀어서 저장한다. 마지막으로 `/etc/cni/net.d` 경로에 pod network를 어떻게 셋업할 지 configuration 파일들을 정의한다.

```
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

```
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

🤔 EKS에서는 어떻게 CNI가 셋팅이 될까 궁금해졌다.

일단 aws container-roadmap repo에 올라온 [이슈](https://github.com/aws/containers-roadmap/issues/71#issue-391916330)를 보면 EKS cluster를 생성할 때 자동으로 deamonset으로 AWS VPC CNI Plugin이 깔리게 되는 것 같다.

Deamonset으로 도는 [AWS VPC CNI Plugin의 리포](https://github.com/aws/amazon-vpc-cni-k8s)를 살펴보면 일단 daemonset object의 volume 설정이 다음과 같이 되어 있다.

```
volumes:
   - name: cni-bin-dir
      hostPath:
      path: /opt/cni/bin
   - name: cni-net-dir
      hostPath:
      path: /etc/cni/net.d
```

daemonset으로 pod가 뜰 때, `/etc/cni/net.d`에 `10-aws.conflist`를 넣게 된다.

amazon-vpc-cni-k8s/misc/10-aws.conflist
```
{
  "cniVersion": "0.3.1",
  "name": "aws-cni",
  "plugins": [
    {
      "name": "aws-cni",
      "type": "aws-cni",
      "vethPrefix": "__VETHPREFIX__",
      "mtu": "__MTU__"
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true},
      "snat": true
    }
  ]
}
```

[AWS VPC CNI Plugin Proposal](https://github.com/aws/amazon-vpc-cni-k8s/issues/214#issuecomment-493543581)를 보면 L-IPAM daemon이 돌아가는 것을 확인 할 수 있다. 

> The L-IPAM daemon is responsible for attaching elastic network interfaces to instances, assigning secondary IP addresses to elastic network interfaces, and maintaining a "warm pool" of IP addresses on each node for assignment to Kubernetes pods when they are scheduled.
[EKS document](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)

[AWS VPC CNI Plugin Repo의 이슈](https://github.com/aws/amazon-vpc-cni-k8s/issues/214#issuecomment-493543581)를 보면서 GKE는 Calico CNI Plugin을 사용하는 것을 알 수 있었다. EKS는 AWS VPC CNI Plugin으로 설정되어 있기 때문에 [인스턴스가 가질 수 있는 ENI와 ENI당 할당 가능한 IP 숫자 제한](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)만큼 pod를 만들 수 있다.

[2020년 2월 14일에 VPC CNI Version 1.6이 릴리즈](https://aws.amazon.com/about-aws/whats-new/2020/02/amazon-eks-announces-release-of-vpc-cni-version-1-6/)되었다고 어나운스가 되었네. VPC CNI에 다양한 Configuration Variable들이 있구나. `WARM_ENI_TARGET`, `WARM_IP_TARGET`, `MINIMUM_IP_TARGET` 등도 있구나. 미리 pod에 할당할 IP를 deadmon으로 돌고 있는 ipam이 미리 확보하고 있을 수도 있구나. 이제 `WARM_IP_TARGET`를 30으로 하고 이제 30개의 pod가 ip를 할당 받으면 이제 30개의 ip를 확보하려고 하겠지. 근데 이렇게 하면 이제 subnet의 할당 가능한 ip를 빠르게 고갈 시킬 수 있으니깐 이제 `MINIMUM_IP_TARGET`가 추가되어서 이제 이 값을 30으로 하고 `WARM_IP_TARGET`를 2로 하면 이제 30개를 확보를 동일하게 하지만 이제 30개가 pod가 deploy되서 할당되고 나면 이제 ipam daemon는 2개만 미리 ip를 확보 해둔다.

## 7 GCP Kubernetes Best Practices videos

### [Building small containers](https://youtu.be/wGz_cbtCiEA)

Performance 측면에서 small container가 build, push, pull하는데 유리하다. 여기서는 Google container registry 서비스에서 base image를 cache하고 있기 때문에 push에서는 push하는 time이 크게 차이 안난다고 한다.

기본적으로 container 사이즈를 줄이기 위해서 사용하고 있었던 alpine base image 사용하기와 multi stage build를 설명하고 있다.

그리고 small container일 수록 보안적으로 노출 될 수 있는 부분이 적다. 여기서는 Container Registry Vulnerability Scanning service로 go:onbuild의 container와 multi staged build의 image를 scan해서 vulnerability가 큰 사이즈의 컨테이너가 더 많은 것을 보여준다.

[AWS ECR에서도 2019년 10월에 Image scanning 기능을 출시했구나.](https://aws.amazon.com/about-aws/whats-new/2019/10/announcing-image-scanning-for-amazon-ecr/)

### [Organizing Kubernetes with Namespace](https://youtu.be/xpnZX3if9Tc)

기본적으로 생기는 Kubernetes
- default
- kube-system
- kube-public

active namespace를 편리하게 관리할 수 있는 Tool
- kubens: switch your active namespace to the namespace you want
- 귀찮게 kubectl get pods --namespace=something 처럼 namespace option을 지정하는 대신에 kubens로 active namespace를 바꿔서 관리

Cross Namespace Communication
- Services in Kubernetes expose their endpoint using a common DNS pattern \
  `<Service Name>.<Namespace Name>.svc.cluster.local`
- 이제 그냥 `servicename`으로 하거나 같은 namespace에 동일한 이름의 서비스가 있다면 `servicename.namespacename`으로!

어떻게 namespace를 managable하게 관리할 수 있을까?

🤔 결국은 namespace도 어느정도의 isolation을 팀에게 줄 건지에 따라서 결정되겠지. 아주 작은 팀에서는 그냥 default namespace를 쓰는 것이 충분할 수 있고, 팀이 더 커지게 되면 이제 서로의 팀들이 독립성을 줄 수 있도록 namespace를 구분하거나 이제 정말 그냥 API로 서로 독립적으로 통신하면 되면 이제 cluster로 나눌 수 있는 것이겠지. Monolithic application vs microservice architecture 중에 조직에서 어떤 것이 필요할지 결정하는 것과 Namespace 관리가 비슷한 이슈인것 같다.

### [Kubernetes Health Checks with Readiness and Liveness Probes](https://youtu.be/mxEvAPQRwhw)

Types of Health Checks
1. Readiness
   - by default, Kubernetes will start sending traffic as soon as the process inside the container start.
2. Liveness
   - restart a pod

Types of Probes
1. HTTP: 200대 response status받으면 success
2. Command: exit status가 zero이면 success
3. TCP: connection establish하면 success

Configuring Probes
- initialDelaySeconds
  - P99 startup time or average time with buffer
- periodSeconds
- timeoutSeconds
- successThreshold
- failureTrhreshold

### [Setting Resource Requests and Limits in Kubernetes](https://youtu.be/xjpHggHKm78)

Requests and Limits

cpu의 경우 limit을 넘어가려면 restrict해서 performance가 안 좋아지지만 계속 실행된다. 하지만 memory같은 경우 limit을 넘어가면 이제 그 container는 terminate된다.

~~resource request가 지금 node가 사용가능한 resource를 넘어가게 되면 이제 그 pod pending 상태가 되고 이제 pending인 pod보다 priority가 낮은 pod가 이제 evict되고 queue에서 기다리는 priority가 높은 pod가 schedule 된다.~~ request resource랑 실제로 node에서 사용중인 resource는 다르다! 그래서 pending state는 이제 requests resource확보가 노드에서 안되니깐 pending상태가 되는 거고 이제 이 상태에서는 따로 running중인 pod를 kill할 필요 없겠지. 근데 이제 실제로 사용하는 리소스가 이제 requests를 넘어서 limit까지 가고 이제 node전체로 봤을 때 node의 resource를 넘어가게 되면 이제 Kubernetes는 이제 자원 확보를 위해서 pod를 kill해야겠지!

node로 사용되는 EC2 instance의 vCPU가 2인데, request cpu를 2.5 CPU로 한다고 하면 이 pod는 계속 실행될 수 없을 것이다. \
🤔 이런 경우에 evict는 어떻게 되는거지? => evict는 안되고 이제 pending state로 남아있겠지!

이제 namespace에서도 ResourceQuota랑 LimitRange를 사용할 수 있다. `kind: ResourceQuota`로 이제 `requests.cpu`, `request.memory`, `limits.cpu`, `limits.memory`를 설정해서 namespace의 container들의 합이 이것들을 넘지 않도록 할 수 있다. `kind: LimitRange`는 이제 전체 namespace가 아니라 각각의 container에 default, limit, max, min를 설정할 수 있다. default를 설정안하고 max만 한다면 이제 default값이 max가 된다. default를 지정안하고 min가 있다면 이제 default값은 min값이 된다. 

GKE의 auto scaler는 이제 node가 requests를 만족할 수 없어서 이제 pending state가 된 pod가 있으면 이제 node를 더 추가해서 그 pod를 실행한다. \
🤔 pending state가 있다고 무조건 evict되는 것 같지는 않다? pending state인데 prority가 낮은 running pod가 있을 때만 evict가 되는건가? -> 실제 사용되는 resource memory가 node memory를 넘어가면 이제 evict가 진행되는거지!

Overcommitment

이제 requests가 있고 Limit이 있는데, pod가 requests보다 Limit까지 더 많이 쓸 수 있다. 결과적으로 이제 Node가 가지고 있는 리소스보다 더 많이 사용할 수 있다. CPU같은 경우는 이제 compress해서 성능이 느려지지만 제한해서 계속 작업을 할 수 있는데, 이제 memory같은 경우에는 Out Of Memory로 이제 전체 시스템이 다운될 수 있다. 이제 노드의 리소스를 넘어가게 되면 이제 overcommitted state가 되고 이제 Kubernetes가 resource를 확보하기 위해서 어떤 pod를 terminate할지 결정해야 한다. 이 결정에 있어서 pod의 priority에 따라서 결정되고 같은 priority라고 하면 이제 requests resource보다 더 많이 사용하고 있는 pod가 terminate된다. 

Limits and requests for CPU resources are measured in cpu units. One cpu, in Kubernetes, is equivalent to:

```
1 AWS vCPU
1 GCP Core
1 Azure vCore
1 IBM vCPU
1 Hyperthread on a bare-metal Intel processor with Hyperthreading
```

### [Terminating with Grace](https://youtu.be/Z_l_kE1MDTc)

It's important that your application can handle termination gracefully(need to hand SIGTERM message)

Kubernetes Termination Lifecycle
1. Pod in Terminating State
2. The preStop Hook is excueted
   - If you application doesn't gracefully shut down when receiving a sigterm, you can use the preStop hook to trigger a graceful shutdown.
3. SIGTERM signal sent to pod
4. terminationGracePeriodSeconds안에 이제 container가 종료되면 이제 다음 step이 진행되고, 근데 아직도 container가 running중이면 SIGKILL 메세지를 보낸다. (terminationGracePeriodSeconds는 preStop Hook과 SIGTERM을 처리하는 것과 parellel하게 count된다)

### [Mapping External Services](https://youtu.be/fvpq4jqtuZ8)

`kind: Service`를 `type: ClusterIP`로 만들어서 이제 여기서 정의한 name으로 가리킬 수 있도록 하고, `kind: Endpoints`에 이제 ip address와 port를 정의해서 이제 이쪽으로 request가 가도록 한다.

Kubernetes안에서 MongoDB가 돌고 있는게 아니라 이제 Virtual Machine에서 별도로 MongoDB가 돌고 있다고 할 때 Kubernetes의 service처럼 이제 이 MongoDB를 연결할 수 있는 것. 쿠버네티스 클러스터안에는 없지만 이제 pod에서 이제 mongdb라는 서비스 이름으로 요청할 수 있게 되는 것.

이제 virtual machine이 같은 VPC에 있고 private IP address를 이제 Endpoints service에 등록해서 연결할 수 있겠지만, 대부분의 Database나 그런것들이 DNS를 제공한다. 그럴 때는 이제 `kind: Service`를 `type: ExternalName`로 만들어서 해당 DNS로 redirect할 수 있다. This service will do a simple CNAME redirect at the kernel level so there's very minimal impact on your performance. 근데 이 방법은 port가 static하게 되어 있으면 application에서 바꿀 필요가 없는데, 이제 영상의 예제처럼 test와 prod의 MongoDB instance가 다른 port가 설정되고 이게 dynamic하게 설정된다고 하면 한계점이 있다. 이제 IP가 변경되지 않는다고 하면 이제 주어진 DNS lookup을 해서 ip들을 Endpoints 서비스에 적용해서 할 수 있겠지만, 내가 경험한 상황에서는 이러한 IP들이 안바뀐다는 것을 보장할 수 없어서 활용하기 힘들 것 같다.

🤔 이제 쿠버네티스 클러스트를 운영하고 외부 데이터베이스를 RDS같은 것을 사용한다고 하면 ExternalName service type을 사용해서 DNS redirect하는 것도 생각해볼 수 있겠다. 근데 그냥 환경변수로 그냥 database DNS를 환경별로 그냥 주입해서 연결하는 것보다 장점이 있는 걸까???

### [Upgrading your Cluster with Zero Downtime](https://youtu.be/ajbC1yTW2x0)

GKE로 zero downtime upgrade 설명

Upgrading Nodes with Zero Downtime
1. Rolling Update
2. Migration with Node Pools

지금 이 글을 작성하는 2020년 2월 12일 기준으로 GKE는
- Stable channel: 1.14.10-gke.17
- Regular channel: 1.15.7-gke.23

AWS EKS Kubernetes versions
- 1.14.9
- 1.13.12
- 1.12.10

2019년 10월 4일에 [Amazon EKS now supports Kubernetes version 1.14](https://aws.amazon.com/about-aws/whats-new/2019/09/amazon-eks-now-supports-kubernetes-version-1-14/)가 공지되었네. 

## [Vitess: Sharded MySQL on Kubernetes](https://youtu.be/E6H4bgJ3Z6c)

🤔 Youtube에서 사용하였고 Borg때부터 stateless app으로 적용되어 k8s에 바로 활용 될 수 있었구나! \
🤔 이 영상에서는 Kubernetes위에서 MySQL를 Vitess로 운영하는 것을 설명했는데, major adoptor인 Slack은 2019 최근 Kubecon에서 아직 Kubernetes위에 운영하지 않고 EC2위에 운영하고 있다고 했다. 그리고 다른 우선순위가 있어서 계속 EC2에 migration을 한다고 했다. \
🤔 제일 궁금했던 것이었는데 영상 마지막 Q&A시간에 질문이 있었다. Vitess가 AWS MySQL과 비교해서 장점을 물었는데, 제한 없이 scale이 가능하고 instance size를 선택할 필요없이 더 딱 맞는 사이즈를 운영할 수 있고, 마지막으로 가장 중요하게 AWS에 갇혀 있지 않고 migration를 할 수 있는 장점이 있다고 설명한다. Vitess를 보면서 Kubernetes를 진짜 멋있게 쓰려면 Database도 Kubernetes에 올리고 특정 Cloud service vendor에 갖히지 않고 비교적 쉽게 migration할 수 있을 것이라 생각했는데, 이 영상에서 그 부분을 다시 한번 강하게 때린 것 같다. \
🤔 Demo에서 Materialized view를 생성하여서 활용하는 것을 보여줬다. Vitess로 쉽게 Materialized view를 생성하네? MySQL에서 내부적으로 쉽게 Materialized view를 생성할 수 있는 방법이 있는건가? \
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
