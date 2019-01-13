# Play kubernetes

## Minikube

Minikube은 VM 위에다가 하나의 노드가 있는 클러스터를 생성해준다. 
Minikube로 로컬 환경에서 쉽게 Kubernetes를 테스트 해 볼 수 있다. 
production 환경에서는 물론 Multiple-Node etcd, Multi-master, Multi-worker로 구성하는 것이 best practice이다.

### minikute setting 

* [VirtualBox 설치](https://www.virtualbox.org/)
* minikube v0.32.0 설치 
`curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.32.0/minikube-darwin-amd64 && chmod +x minikube && sudo cp minikube /usr/local/bin/ && rm minikube`
* Homebrew로 kubectl 설치
`brew install kubernetes-cli`
* minikube 시작 `minikube start --kubernetes-version v1.12.4 --extra-config=apiserver.authorization-mode=RBAC --memory=4048`

실습을 할 때 Kubernetes의 최신버전은 `v1.13.1`이었음. minikube의 호환성을 생각해서 `v1.12.4`을 사용함. 
minikube 0.32.0 release note를 보면 `Make Kubernetes v1.12.4 the default`로 나와있다.
RBAC(Role-Base Access Control)방식을 사용하기 위해서 `--extra-config=apiserver.quthorization-mode=RBAC`로 설정하였다.

#### minikube 상태 확인

```
$ minikube status

There is a newer version of minikube available (v0.32.0).  Download it here:
https://github.com/kubernetes/minikube/releases/tag/v0.32.0

To disable this notification, run the following:
minikube config set WantUpdateNotification false
host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.100
```

kubectl이 설정이 제대로 되었는지 확인. cluster info 가져와보기.
```
$ kubectl cluster-info

Kubernetes master is running at https://192.168.99.100:8443
KubeDNS is running at https://192.168.99.100:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

Kubectl로 Kubernetes cluster에 접근하기 위해서는 master node endpoint를 알아야 하고, 
credential이 있어야 한다. minikube를 start할 때 kubeconfig file이 생성된다.
`~/.kube/config`에 cluster에 접근하기 위한 정보가 있는 것을 확인할 수 있다.

## Deployment

> A Deployment controller provides declarative updates for Pods and ReplicaSets.

Deployment objects는 Prod와 ReplicaSets 설정할 수 있게 한다. 아래와 같이 deployment type의 k8s object를 yaml파일로 정의한다.

```yaml
# webserver.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver
  labels:
    app: webserver
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable-alpine
        ports:
        - containerPort: 80
```

`$ kubectl create -f webserver.yaml`

```
$ kubectl get deployments

NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
webserver   3         3         3            3           28m
```

replica를 3으로 설정 했기 때문에 pod 3개가 만들어졌다.

```
$ kubectl get replicasets

NAME                   DESIRED   CURRENT   READY   AGE
webserver-77d8994b6f   3         3         3       29m

$ kubectl get pods

NAME                         READY   STATUS    RESTARTS   AGE
webserver-77d8994b6f-6jg7m   1/1     Running   0          32m
webserver-77d8994b6f-9phwg   1/1     Running   0          32m
webserver-77d8994b6f-flx9k   1/1     Running   0          32m
```

pod는 같은 host에서 schedule되고 같은 network namespace와 같은 volume에 마운트되는 deployment의 unit이다.

deployment에 label를 `app:webserver`로 설정했기 때문에

```
$ kubectl get deployments -l app=webserver

NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
webserver   3         3         3            3           26s
```

pods의 label이 `app:nginx`로 설정되었기 때문에

```
$ kubectl get pods -l app=nginx

NAME                         READY   STATUS    RESTARTS   AGE
webserver-77d8994b6f-6kfk8   1/1     Running   0          26s
webserver-77d8994b6f-7q4sf   1/1     Running   0          26s
webserver-77d8994b6f-pz5gw   1/1     Running   0          26s
```

```
$ kubectl describe deployment webserver

...
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:stable-alpine
...
```

다른 image로 rollout하고 싶다면,

```
$ kubectl set image deployment.v1.apps/webserver nginx=nginx:alpine --record=true

$ kubectl describe deployments webserver

...
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:alpine
...
```

option `--record=true`를 했기 때문에 history revision2에 명령어가 남아 있다.
```
$ kubectl rollout history deployment.v1.apps/webserver

deployment.apps/webserver
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment.v1.apps/webserver nginx=nginx:alpine --record=true
```

revision 1은 처음에 deploy했던 `nginx:stable-alpine` image인 것을 확인 할 수 있다.

```
$ kubectl rollout history deployment.v1.apps/webserver --revision=1

deployment.apps/webserver with revision #1
Pod Template:
  Labels:       app=nginx
        pod-template-hash=3289273045
  Containers:
   nginx:
    Image:      nginx:stable-alpine
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

처음 배포 했던 image로 rollback을 하고 싶으면,
```
$ kubectl rollout undo deployment.v1.apps/webserver --to-revision=1
```

다시 Pod의 container image가 `nginx:stable-alpine`로 바뀐 것을 확인 할 수 있다.

## Service

k8s에서 service는 pod들을 grouping을 할 수 있다.

이번엔 service type의 k8s object를 정의.

```yaml
# service-type.yaml

kind: Service
apiVersion: v1
metadata:
  name: webserver-svc
  labels:
    run: webserver-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
```

```
$ kubectl create -f service-type.yaml
```

```
$ kubectl get svc

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP        22h
webserver-svc   NodePort    10.110.65.165   <none>        80:30248/TCP   8s
```

service type을 NodePort로 설정하였기 때문에, ClusterIP와 더불어 port(30000~32767)가 service에 mapping된다.
`80:30248/TCP` 30248번 port가 webserver-svc에 mapping된 것을 위에서 확인 할 수 있다.

```
$ minikube ip

http://192.168.99.100
```

minikube가 돌고 있는 VM의 ip에 이제 30248번 포트로 연결하면 nginx default page가 뜨는 것을 확인 할 수 있다. `192.168.99.100:30248`

service type은 아래와 같은 종류가 있다.

- ClusterIP : servicer가 cluster안에서만 접근 가능
- NodePort
- LoadBalancer : 외부 Loadblancer와 연결할 수 있도록
- ExternalName : CNAME과 같은 externalName과 mapping

#### client IP issue

minikube는 single node인데, 만약 node가 세 개가 있다고 가정해보자.
그리고 node A에만 pod(endpoint)가 있다고 가정하자.
아래처럼 client가 node B:nodePort로 packet을 보냈다. 
그러면 endpoint는 node A에 있기 때문에 Node B가 source IP를 자신의 IP로 바꾸고 destination IP를 endpoint 바꿔서 routing하게 된다.
이 상황에서 source IP가 바뀌었기 때문에 원래 source IP인 client IP가 보존되지 않게 되는 문제가 생긴다.

```
           client
             \ ^
              \ \
               v \
   node A <--- node B
    | ^   SNAT
    | |   --->
    v |
 endpoint
``` 

그래서 `externalTrafficPolicy`를 값을 Local로 설정해서 다른 node로 routing하지 않고,
원래의 client IP를 보존할 수 있도록 할 수 있다. 하지만 위에서 설명한 것처럼 Node B:NodePort로 packet을 보내면,
Node B에는 endpoint가 없기 때문에 packet이 drop되게 된다. packet loss가 발생하게 되는 것이다.

#### loadbalancer issue

> In Kubernetes v1.0, Services are a “layer 4” (TCP/UDP over IP) construct, the proxy was purely in userspace. In Kubernetes v1.1, the Ingress API was added (beta) to represent “layer 7”(HTTP) services, iptables proxy was added too, and became the default operating mode since Kubernetes v1.2.

node에는 kube-proxy가 돌아가고 있다.
예전에 proxy-mode가 userspace mode일 때는, Service의 ClusterIP의 iptable을 통해 traffic이 kube-proxy이 전달되면 proxy port로 연결된 Service의 pod들로 round-robin 방식으로 traffic를 proxy했다.
하지만 v1.2부터 default로 설정되는 iptables proxy mode는 iptables에 random하게 선택되는 pod에게 traffic이 전달된다.

[Virtual IPs and service proxies](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#caveats-and-limitations-when-preserving-source-ips)

그래서 client IP를 보존하려고 할 때, AWS loadbalancer는 pod단위로 load balancing을 못 하고, node 단위로 load balancing이 되게 된다.

[Caveats and Limitations when preserving source IPs](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#caveats-and-limitations-when-preserving-source-ips)

## Liveness and Readiness

pod type의 object를 생성

```
# pod-type.yaml

apiVersion: v1
kind: Pod
metadata:
  name: webserver
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 3
```

`$ kubectl create -f pod-type.yaml`

`liveness`설정으로 kubelet이 application의 health를 관리하도록 한다.
위에서 liveness로 httpGet설정을 해서 `/` path로 healthcheck를 하도록 한다.
정상적으로 nginx page가 나오는 걸 확인 할 수 있다.

**kubelet**

> he kubelet is an agent which runs on each worker node and communicates with the master node.
> The kubelet connects to the container runtime using Container Runtime Interface (CRI). The Container Runtime Interface consists of protocol buffers, gRPC API, and libraries.

이번에 `port: 80`을 일부로 fail되게 `port: 88`로 해보면 event에 fail이 생기는 걸 확인할 수 있다.

```
$ kubectl describe pod webserver

...
Liveness probe failed: Get http://172.17.0.3:88/: 
dial tcp 172.17.0.3:88: getsockopt: connection refused
...
```

readiness는 application이 traffic을 처리하기전에 준비가 되었다는 condition을 주는 설정이다.

## Istio

> Istio is an open platform for providing a uniform way to integrate microservices, manage traffic flow across microservices, enforce policies and aggregate telemetry data. Istio's control plane provides an abstraction layer over the underlying cluster management platform, such as Kubernetes, Mesos, etc.

Microservice architecture에서는 service간 복잡하게 연결되어 있는데 Service mesh로 transparent하게 할 수 있다. 
Istio를 통해서 이러한 service mesh를 편하게(?) Kubernetes에 적용할 수 있다. 

### setup

> The setup and configuration of Istio using Helm is the recommended install method for installing Istio to your production environment as it offers rich customization to the Istio control plane and the sidecars for the Istio data plane.

Kubernetes에서 deploy할 때, Deployments, Service, Volume, Ingress 설정 등을 하나씩 하게 되는데 이것들 묶어서 템플릿화한 것이 **Chart**라고 불린다.
**Helm**은 Kubernetes의 package manager로 이 **charts**를 설치,삭제,업데이트를 할 수 있다.
그리고 **Helm**은 client이고 **tiller**는 k8s cluster에서 run하는 server이다.

Istio 공식문서에서 Helm을 사용하여 설치하는 것을 추천한다. 

[Istio document](https://istio.io/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install)
에서 helm template을 이용하는 방법과 helm + tiller를 이용하여 설치하는 방법을 설명하고 있다. 
나는 tiller를 사용하는 방법으로 진행. 

#### helm을 설치(v2.12.1). 

`brew install kubernetes-helm`

#### service account 생성

tiller에게 권한을 주기 위해서 service account를 생성하고, 
Role-Based Access Authorizer module을 사용하여 생성한 service account에 cluster-admin role을 부여한다.

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

#### 최신 Istio release 다운로드

```
$ curl -L https://git.io/getLatestIstio | sh -

# istioctl를 global하게 사용하기 위해서 PATH 추가 
$ export PATH="$PATH:/Users/jaemyunlee/playground/kubernetes/istio-1.0.5/bin"
```


`istio-1.0.5/install/kubrnetes/helm/helm-service-account.yaml`에 service account생성과 clusterrole binding하는 yaml file이 이미 존재해서 그 파일을 사용한다.

`$ kubectl apply -f istio-1.0.5/install/kubernetes/helm/helm-service-account.yaml`

`$ kubectl get serviceAccount -n kube-system`을 해보면 tiller가 생성된 것을 확인할 수 있다.

#### helm과 tiller를 통해서 istio 설치

`$ helm init --service-account tiller`

`$ helm install istio-1.0.5/install/kubernetes/helm/istio --name istio --namespace istio-system`


설치 확인. istio-system namespace에 다양한 service들이 생성된 걸 확인할 수 있다.

`$ kubectl get svc -n istio-system`

### test with local images

Docker daemon을 통해서 local machine에 있는 Docker image를 사용할 수 있도록 설정한다.

`$ eval $(minikube docker-env)` 

간단하게 Service A ==> Service B ==> Service C로 요청하는 시나리오를 구성해본다. 
필요한 docker image를 build.

```
$ docker build -t sample-app:a --build-arg SERVICE_TYPE=A ./sample-app/

$ docker build -t sample-app:b --build-arg SERVICE_TYPE=B ./sample-app/

$ docker build -t sample-app:c --build-arg SERVICE_TYPE=C ./sample-app/
```

Minikube로 nginx를 deploy한 것처럼 yaml파일(istio-sample-app-deploy.yaml)을 만들었다. 
Istio에서 envoy가 traffic을 intercept할 수 있도록 envoy sidecar를 달아줘야 한다. istio ctl를 사용하면 간단히 kube-inject 명령어로 sidecar를 설정할 수 있다. 

`kube-inject`를 통해서 envoy sidecar를 달아준다.

`kubectl apply -f <(istioctl kube-inject -f istio-sample-app-deploy.yaml)`

```
$ kube-ctl get pods

NAME                                READY   STATUS    RESTARTS   AGE
service-a-deploy-575ff68ccb-4b2vn   2/2     Running   0          18m
service-b-deploy-74548696f7-96fmv   2/2     Running   0          18m
service-c-deploy-755d4b6658-xfgsp   2/2     Running   0          18m
```

sidecar가 붙어서 `1/1`이 아니라 `2/2`인 것을 확인할 수 있다.

이제 Gateway를 설정하여 ingress traffic을 받을 수 있도록 한다.
VirtualService는 routing rule을 정의한 것인데, destination service을 service-a로 설정하였다.

```
# istio-sample-app-routing.yaml

---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtual-service
spec:
  hosts:
  - "*"
  gateways:
  - gateway
  http:
  - route:
    - destination:
        host: service-a
        port:
          number: 8000
```

`$ kubectl apply -f istio-sample-app-routing.yaml`

```
$ kubectl get gateway

NAME      AGE
gateway   14m
```

minikube는 external loadbalancer가 지원이 안되기 때문에 ingress service를 사용한다.

`$ kubectl -n istio-system get service istio-ingressgateway`

`80:31380/TCP`로 PORT가 mapping되어 있기 때문에

```
$ curl $(minikube ip):31380/service

{"SERVICE_TYPE":"C","SERVICE_HOST":"10.104.52.109","SERVICE_PORT":"80"}
```

#### service discovery

Dynamic하게 올라가고 내려가는 Container환경에서는 Service discovery가 필요하다. 
Kubernetes는 기본적으로 worker node에서 실행되는 kubelet이 Active service들을 환경변수로 저장한다. 
예제로 생성한 `app.py`를 보면 환경변수 값을 return 해주도록 하였다.

```
# sample-app./app.py

return json({
        'SERVICE_TYPE': SERVICE_TYPE,
        'SERVICE_HOST': os.getenv(f'SERVICE_{SERVICE_TYPE}_SERVICE_HOST', None),
        'SERVICE_PORT': os.getenv(f'SERVICE_{SERVICE_TYPE}_SERVICE_PORT', None)
    })
```

service의 name을 service-a, service-b, service-c으로 설정하였다. 따라서 SERVICE_A_SERVICE_
HOST, SERVICE_A_SERVICE_PORT 환경변수로 service의 HOST IP와 PORT를 알 수 있다.

```
$ curl 192.168.99.100:31380/

{"SERVICE_TYPE":"A","SERVICE_HOST":"10.98.220.183","SERVICE_PORT":"80"}
```

하지만, 이 방법은 pod가 생성된 이후에 서비스가 생기면 이 방법으로 서비스의 정보를 가져올 수 없다.

##### DNS 이용하여 service discovery

```
$ kubectl get pods -n=kube-system | grep "dns"

coredns-576cbf47c7-cckr8  1/1  Running  0  9h
coredns-576cbf47c7-cj457  1/1  Running  0  9h
```

kube-system namespace에서 작동중인 pod중에 dns 이름을 가진 pod를 찾아본다. 그러면 기본적으로 coredns가 작동중인 걸 알 수 있다. 
CoreDNS도 CNCF의 project중 하나이고, Kubernetes cluster DNS으로 사용될 수 있는 DNS server이다.


테스트를 위해서 간단한 nginx pod를 만든다. 
그리고 container에 들어가서 `nslookup`과 `curl`를 사용하도록 package를 설치 해준다.

```
$ kubectl apply -f pod-type
$ kubectl exec -ti webserver -- /bin/bash

# apt-get update
# apt-get install dnsutils
# apt-get install curl
```

service-a를 dns resolution 해보면 `10.98.220.183`이 된다. 
service name으로 request하면 정상적으로 리턴하는 것을 볼 수 있다.  

```
# nslookup service-a

Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   service-a.default.svc.cluster.local
Address: 10.98.220.183

# curl service-a:8000/

{"SERVICE_TYPE":"A","SERVICE_HOST":"10.98.220.183","SERVICE_PORT":"80"}
```

DNS record는 `my-svc.my-namespace.svc.cluster.local`형식이 된다. 
default namespace에 service-a로 service name을 정의했기 때문에 `service-a.default.svc.cluster.local`이 되는 것이다.

정상적으로 Envoy를 통해서 가는지 확인하기 위해서 envoy 로그를 확인해본다.

```
$ kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
service-a-deploy-5b5f57447b-w5fmp   2/2     Running   0          81m 

$ kubectl log -f service-a-deploy-5b5f57447b-w5fmp istio-proxy
```

이제 `curl 192.168.99.100:31380/service`로 request하며 inbound와 outbound가 찍히는 걸 확인할 수 있다.

### tracing

Envoy sidcar가 trace를 위한 header를 만든다. 
Envoy가 header와 함께 Mixer에게 전달하면 Mixer는 tracing system으로 보내게 된다. 
CNCF에서 관리는 되는 Jaeger를 사용해서 tracing을 수집하고 저장하고 UI에서 Query할 수 있다.

1. Envoy : Zipkin format의 B3 HTTP headers 생성
2. Mixer : Mixer는 Jaeger tracing system에 보낸다. (Jaeger는 Zipkin format이랑 호환됩)

`$ kubectl get pod -n istio-system -l app=jaeger`를 해보니깐 해당되는 pod가 없다. helm으로 install할 때 `--set tracing.enabled=true` 옵션을 줘야한다.

#### upgrade istio with helm

`$ helm upgrade istio istio-1.0.5/install/kubernetes/helm/istio --set tracing.enabled=true`

update를 해서 revision이 2로 된 것을 확인 할 수 있다. helm으로 rollback도 가능!

```
$ helm list

NAME    REVISION ...   
istio   2        ...
```

이제 istio-tracing pod가 있는 걸 확인 할 수 있다.

```
$ kubectl get pod -n istio-system

...
istio-tracing-6445d6dbbf-8tcfc  1/1  Running  0  6m6s
...
```

istio-pilot deployment object의 sampling 설정을 변경한다.
테스트를 위해서 모든 request를 sampling하도록 설정한다.

```
 - name: PILOT_TRACE_SAMPLING
   value: "100.0" 
``` 

istio-policy deployment의 설정을 보면 `trace_zipkin_url`이 있는 것을 확인 할 수 있다.

`kubectl -n istio-system edit deploy istio-policy`


```
containers:
 80       - args:
 81         - --address
 82         - unix:///sock/mixer.socket
 83         - --configStoreURL=k8s://
 84         - --configDefaultNamespace=istio-system
 85         - --trace_zipkin_url=http://zipkin:9411/api/v1/spans
 86         - --numCheckCacheEntries=0 
```

그리고 istio-tracing deployment object 설정을 보면 `jaeger all-in-one` 이미지가 사용된 것을 볼 수 있다.

`kubectl -n istio-system edit deploy istio-tracing`

`image: docker.io/jaegertracing/all-in-one:1.5`

이제 port forwarding으로 Jaeger dashboard를 연결하고 ingress gateway로 reqeust하면 tracing 정보가 나오는 것을 확인할 수 있다.

`$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &` 

envoy가 header를 생성할 때, trace header가 있으면 child span을 만들지만 없으면 새로운 parent span을 만들게 된다.
sample app에서 serviceA에서 serviceB로 request할 때 trace header정보를 건내줘야 한다.
하나의 span에 service A => B => C 가 될 수 있도록 header를 전달하도록 하였다.

```
async with aiohttp.ClientSession() as session:
    async with session.get(url, headers=trace_header) as resp:
        return json(await resp.json())
```

Tracing을 할 때 user ID던가 뭔가 추가적인 정보를 담아야할 경우가 있다. 
이럴 경우에는 Tracer를 만들어서 tag정보를 추가하거나 child span을 만들 수 있다.  


### Metric

Prometheus도 CNCF 프로젝트중 하나인데, Istio에는 prometheus adapter가 있어서 쉽게 metrics를 prometheus에 보낼 수 있다.

`kubectl apply -f num-of-requests.yaml `

`num-of-requests.yaml`에서 세 부분(instances, handler, rules)로 나눌 수 있다.

`kind:metric`

Envoy가 보낸 request attribute 바탕으로 Mixer가 Metric을 생성하는 방법을 정의한다.

>The primary attribute producer in Istio is Envoy, although Mixer and services can also introduce attributes.

[attributre 종류들](https://istio.io/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)

`kind:prometheus`

Prometheus backend에서 처리 될 수 있도록 prometheus type의 format으로 변환해주는 adapter를 설정함.
dimensions로 설정한 것들이 label이 된다. Prometheus 말고도 다른 Adapter들이 존재한다.

`kind:rule`

여기서 rule정해서 match되는 것들만 instance들을 handler에 보내도록 설정할 수도 있다.