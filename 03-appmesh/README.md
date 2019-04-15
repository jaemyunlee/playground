# App mesh

작성일자 2019/04/15

작년 말에 App mesh가 preview로 나와서 관심을 가지고 있었는데,
최근 3월 27일 [The App Mesh service is now generally available for production use.](https://aws.amazon.com/about-aws/whats-new/2019/03/aws-app-mesh-is-now-generally-available/)라고 올라왔다.
처음 Preview일 때는 CLI로 설정을 해야 되었다. 지금은 Console에서 App mesh를 설정할 수도 있고, Cloudformation에서 Appmesh resource들을 생성할 수 있게 되었다.

## 기대감

AWS를 많이 활용하는 상황에서 App mesh를 이용하면 다른 AWS service 쉽게 연동하면서 편리하게 Service mesh를 구축할 수 있을 것이라 기대했다.

## 테스트를 하면서 받은 인상

App mesh가 더욱 active하게 사용될려면 더 많은 feature들이 추가 되어야 될 것 같다는 생각이 들었다.
자연스럽게 Istio와 비교를 하게 된다. App mesh가 AWS resources들과 연계되는 장점이 부각되기전까지는 Istio가 👍인 듯.

### Cloudformation에 proxy config in task definition가 없음

App mesh를 사용하기 위해서 ECS의 경우 proxy configuration을 task definition에 설정을 해줘야 한다.
Cloudformation에 App mesh가 추가되었다는 것을 보고 기쁜 마음에 Terraform으로 테스트 환경을 만들기 시작했다. 
App mesh의 mesh, virtual service, route 등을 설정할 수 있지만 정작 ECS에서 설정해야 되는 proxy configuration이
아직 cloudformation에 추가되지 않았다. 이부분은 아직도 CLI에 의존해야 되는 상황.

### Circuit breaker, retry policy 아직 적용중. fault injection은 research중

Istio를 테스트하면서 circuit breaker와 retry policy를 활용하여 지금 redis로 구성한 circuit breaker를 대체하고 싶었다.
App mesh는 이 글을 쓰는 시점에서 circuit breaker와 retry policy를 적용중이다. 
그리고 Istio의 fault injection을 적용하면 좋겠다고 생각했는데 App mesh는 아직 research 단계이다.
[App mesh road map 참고](https://github.com/aws/aws-app-mesh-roadmap/projects/1)

### 부족한 examples

예제를 보면 다른 버전의 서비스를 weight 줘서 routing하는 예제만 찾을 수 있다.
AWS engineer가 점점 더 많은 예제들을 Github repo에 추가한다고 했지만, 참고할 만한 예제들을 부족하다고 느꼈다.
Service mesh를 구축하고 싶었던 이유 중에 하나는 서비스의 metric들을 쉽게 수집하고 싶었던 것이었다.
Cloudwatch agent가 statsd와 collectd plugin이 작년 10월에 [Amazon CloudWatch Agent adds Custom Metrics Support](https://aws.amazon.com/about-aws/whats-new/2018/09/amazon-cloudwatch-agent-adds-custom-metrics-support/)
지원한다고 했다. 그래서 쉽게 Envoy stats의 Sink로 statsd format의 metric을 수집할 수 있을 거라 생각했다. 하지만 이에 대한 예제는 없고, AWS engineer는 필요하면 prometheus로 연결하는 예제를 공유해주겠다고 하였다.
Istio대신에 App mesh를 쓰는 최대 장점은 쉽게 AWS service들과 연동되는 것이라 생각했는데, 아쉬웠다. 

### Fargate는 us-east-1만 지원

이 글을 쓰는 시점에서 Fargate type은 us-east-1만 지원한다. 
별건 아니지만 생각보다 조금 귀찮았던 것은 `111345817488.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy:v1.9.0.0-prod` App mesh용 
Envoy 이미지가 us-west-2에만 있어서 내가 사용하는 region ECR에 다시 push해서 사용해야 했다.
ECS에서 같은 region에 있는 Image를 pull 받아올 때는 요금이 발생하지 않지만 다른 region간 image를 pull 받아야할 때는 요금이 발생한다.
Fargate의 경우에는 task가 fail되서 새로 task를 실행할 때, 다시 image를 pull받게 된다.
(EC2 type은 설정으로 cache에 pull 받은 이미지를 저장해서 재 사용할 수 있다고 알고 있음)
일시적인 장애가 아니라 fatal error로 계속 이 태스크가 재실행되는 상태로 나두면 다른 Region간 pull은 꽤 요금이 나올 수 있는 것이다.

### 🍭🍭 Data plane Envoy 👍👍 🍭🍭

Istio는 Control plane 역할을 하고, Envoy는 data plane 역할을 한다. 
App mesh도 Istio처럼 Control plane역할을 한다. Istio를 테스트할 때는 Envoy가 이렇게 모든 일을 다해주는 훌륭한 일꾼인줄 몰랐다. 
Envoy에 대해서 공부해보니, Fault injection, Rate limit, Health check, cirtcuit breaker, retries, trace, metric 등 많은 부분을 Envoy가 해주고 있었다. 
이렇게 powerful한 Envoy를 App mesh에서는 제대로 활용하지 못하는 것 같아서 아쉽다.

---

## Envoy

- gRPC/protobuf based
- Interacting with the control plane is separated from data plane operation

Envoy는 static하게 설정할 수도 있고, xDS APIs로 dynamic하게 설정할 수 있다.
[Envoy Github repo의 example](https://github.com/envoyproxy/envoy/blob/master/examples/front-proxy/service-envoy.yaml)을 보면 static하게 정의하는 것을 예제를 볼 수 있다.

```
static_resources:
  listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 80
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/service"
                route:
                  cluster: local_service
          http_filters:
          - name: envoy.router
            typed_config: {}
  clusters:
  - name: local_service
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    load_assignment:
      cluster_name: local_service
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8081
```

### Listener

> A listener is a named network location (e.g., port, unix domain socket, etc.) that can accept connections from downstream clients. Envoy exposes one or more listeners.

```
listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 80
```

docker compose를 생성된 service는 80 port가 expose되어 있다. 
Envoy는 80번 port에 bind되고, 80번 port로 오는 reqeust를 받게 된다.

```
filter_chains:
- filters:
  - name: envoy.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager
      codec_type: auto
      stat_prefix: ingress_http
      route_config:
        name: local_route
        virtual_hosts:
        - name: service
          domains:
          - "*"
          routes:
          - match:
              prefix: "/service"
            route:
              cluster: local_service
      http_filters:
      - name: envoy.router
        typed_config: {}
``` 

이제 이렇게 받은 request를 어떻게 할지 filters에 정의되어 있다. filter_chains의 filters list에 정의된 filter가 순차적으로 실행되게 된다. 
여기에서는 filter가 하나만 정의되어 있다. 만약 여기서 filters가 빈 list면 connection을 close하게 된다. 
Enovy는 built-in filter로 HTTP connection manager가 있는데, protobuf의 message type으로 정의한다.

### HTTP connection manager

> HTTP is such a critical component of modern service oriented architectures that Envoy implements a large amount of HTTP specific functionality. Envoy has a built in network level filter called the HTTP connection manager. This filter translates raw bytes into HTTP level messages and events (e.g., headers received, body data received, trailers received, etc.). It also handles functionality common to all HTTP connections and requests such as access logging, request ID generation and tracing, request/response header manipulation, route table management, and statistics.

HTTP connection manager가 여러가지 http filters를 가지고 있는데, 위에서는 router를 사용하고 있다.

### Router

> The router filter implements HTTP forwarding. It will be used in almost all HTTP proxy scenarios that Envoy is deployed for. The filter’s main job is to follow the instructions specified in the configured route table. In addition to forwarding and redirection, the filter also handles retry, statistics, etc.

route_config에 route table이 설정되어 있고, `/service`로 matching되면 해당 cluster로 route를 하게 된다. 

```
clusters:
  - name: local_service
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    load_assignment:
      cluster_name: local_service
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
```

### Cluster

> A cluster is a group of similar upstream hosts that accept traffic from Envoy. Clusters allow for load balancing of homogenous service sets, and better infrastructure resiliency.

localhost 8080번 포트의 python application에 route가 된다. 여러 개의 endpoint에 round robin방식으로 load balancing이 되도록 설정된 걸 볼 수 있다.

### stats

- Store - holds stats
- Sink - protocol adapter (statsd, gRPC, etc.)
- Admin - allows pull access
- Flusher - allows push access
- Scope - discrete grouping of stats that can be deleted