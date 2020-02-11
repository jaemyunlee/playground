# Keep learning project #2 : k8s <!-- omit in toc -->

I played around with Minikube and EKS to understand Kubernetes. I would like to be a kind of expert about Kubernetes. My journey to be an expert about Kubernetes just started!

## History <!-- omit in toc -->

- [Kubernetes Design Principles: Understand the Why - Saad Ali, Google](#kubernetes-design-principles-understand-the-why---saad-ali-google)

## [Kubernetes Design Principles: Understand the Why - Saad Ali, Google](https://youtu.be/ZuIQurh_kDk)

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
