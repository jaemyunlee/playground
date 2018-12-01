# Story

AWS seoul region에서 DNS 장애가 발생했었다. [AWS 글 참조](https://aws.amazon.com/ko/message/74876/)

>> 2018 년 11 월 22 일 서울 리전(AP-NORTHEAST-2)에서 발생한 서비스 중단 상황에 대해 추가적으로 정보를 알려드립니다. 당일 한국시간 오전 8시 19분에서 9시 43분까지 서울 리전에서 EC2 인스턴스에 DNS 확인 이슈가 있었습니다. 이는 EC2 인스턴스에 재귀 DNS 서비스를 제공하는 EC2 DNS 확인 서버군(resolver fleet) 중 정상 호스트 수가 감소했기 때문입니다. 정상 상태의 호스트 수가 이전 수준으로 복원됨에 따라 DNS 확인 서비스는 복원되었습니다. 이번 이슈에서 EC2 인스턴스의 네트워크 연결 및 EC2 외부의 DNS 확인 과정은 영향을 받지 않았습니다.


여러 회사들이 어떻게 이 장애에 대처를 했는지 들어보는 자리에서 AWS provided DNS에서 Google public DNS으로 변경했을 때 정상적으로 작동했다는 의견이 있었다.


먼저 [Google Public](https://dns.google.com/) DNS로 RDS endpoint를 query request를 했을 때,
resolve되어 Endpoint의 IP address가 return되는 것을 확인 할 수 있었다. 그럼 EC2에서 DNS를 변경해주었으면 CF - ELB - EC2 - RDS로 구성된 아키텍쳐에서는 장애해결이 되었다는 것일까?

# My Experiment 

Terraform script로 Test 용 infra를 만들면서 실험을 해보았다. 
RDS를 private subnet에 넣었고, publicly_accessible를 false로 설정해주었다.
public subnet에 있는 EC2 instance로 RDS를 접속 할수 있도록 Security group을 설정하였다.

## test1

```
$ terraform init
$ terraform apply -var-file="test1.tfvars"
```

VPC 설정 중을 아래와 같이 하여, AWS provided DNS가 동작하게 하고 Public DNS hostname을 가지도록 하였다. 


```
enable_dns_support   = true
enable_dns_hostnames = true
```
[enableDnsSupport](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html)

>> Indicates whether the DNS resolution is supported for the VPC. If this attribute is false, the Amazon-provided DNS server in the VPC that resolves public DNS hostnames to IP addresses is not enabled.

[enableDnsHostnames](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-support)

>> Indicates whether the instances launched in the VPC get public DNS hostnames.

EC2의 Private DNS 이외에도 Public DNS가 생기는 것을 볼 수 있다.
Public DNS를 Google Public DNS로 query하면 Public IP가 return되는 것을 확인 할 수 있다.
당연히 Private DNS는 resolve이 안된다.

EC2 instance에 접속하여 DNS에 `google.com`과 private DNS `ip-10-1-1-101.ap-northeast-2.compute.internal`를 query 해보면, 정상적으 IP address를 받는다.
```
$ ssh -i ~/.ssh/key.pem ubuntu@public_ip
$ nslookup google.com
$ nslookup ip-10-1-1-101.ap-northeast-2.compute.internal
```

/etc/resolv.conf 

```
nameserver 10.1.0.2
search ap-northeast-2.compute.internal
```

## test2

```
$ terraform init
$ terraform apply -var-file="test2.tfvars"
```

VPC 설정 중을 아래와 같이 하여, AWS provided DNS 사용을 disable했다. 

```
enable_dns_support   = false
enable_dns_hostnames = false
```



enable_dns_hostname을 false로 설정했기 때문에 Amazon provided DNS가 DNS hostname을 resolve하지 못한다.
test1에서 처럼 EC2 instance에 들어가서 `nslookup`을 해보면 DNS 접속을 못하는 것을 확인할 수 있다. google.com같은 Public Domain뿐만 아니라 AWS private Domain도 못한다.

```
$ ssh -i ~/.ssh/key.pem ubuntu@public_ip
$ nslookup google.com
$ nslookup ip-10-1-1-101.ap-northeast-2.compute.internal
```

당연히 이 EC2 instance로 SSH tunneling을 하여 RDS endpoint에 접속을 할려고 하면,
RDS endpoint를 resolve를 못하니깐 접속을 못한다. 하지만 Google public DNS로 RDS endpoint를 query하고 IP address를 얻어서 접속하면 된다.

RDS endpoint
`ec2-13-125-222-210.ap-northeast-2.compute.amazonaws.com`

Google public DNS로 query

```
{
  "Status": 0,
  "TC": false,
  "RD": true,
  "RA": true,
  "AD": false,
  "CD": false,
  "Question": [
    {
      "name": "ec2-13-125-222-210.ap-northeast-2.compute.amazonaws.com.",
      "type": 1
    }
  ],
  "Answer": [
    {
      "name": "ec2-13-125-222-210.ap-northeast-2.compute.amazonaws.com.",
      "type": 1,
      "TTL": 21599,
      "data": "13.125.222.210"
    }
  ],
  "Comment": "Response from 156.154.67.10."
}

```

Response의 IP address로 접속하면 성공.

그럼 /etc/hosts를 바꿔서 넣어줘도 되겠다.

>> The default action is to query named, followed by /etc/hosts

/etc/hosts에 endpoint와 IP address를 추가해주고, `sudo reboot` 해준다.
```
127.0.0.1 localhost
10.1.3.200 testdb.cmqmchrxqbf4.ap-northeast-2.rds.amazonaws.com
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
```

이제 RDS endpoint로 접속해도 가능하다.

다른 Public Doman도 Query해야되는 경우라면, `/etc/resolv.conf` 에 public DNS를 추가하면 되겠다.

/etc/dhcp/dhclient.conf에다가 Cloudflare의 1.1.1.1 Public DNS랑 Gogole Public DNS 8.8.8.8를 추가해본다.
그리고 `sudo reboot`

```
supersede domain-name-servers 1.1.1.1, 8.8.8.8;
```

그럼 이제 /etc/resolv.conf에 Public DNS가 들어가 있는 것을 확인 할 수 있다.

```
nameserver 1.1.1.1
nameserver 8.8.8.8
search ap-northeast-2.compute.internal
```

RDS endpoint로 접속 성공.

# Conclusion

이번 서울 리전에서 발생한 장애에 대한 공식 설명은 `EC2 인스턴스에 DNS 확인 이슈` 그리고 `이번 이슈에서 EC2 인스턴스의 네트워크 연결 및 EC2 외부의 DNS 확인 과정은 영향을 받지 않았습니다.`이었다.

생각을 해보면 RDS는 동일 VPC에서 뿐만 아니라 Internet을 통해서 접속하는 방법으로도 사용할 수 있다. RDS endpoint는 Private DNS hostname이 아니라고 판단이 된다. 

**따라서 EC2에서 DNS문제로 RDS endpoint를 resolve하지 못하는 문제는 google public DNS와 같은 public DNS로 변경해주었으면 장애를 해결 할 수 있었다고 생각한다.**


내가 관리하는 Service가 다른 리전에 있어서 이러한 장애를 겪지 않았는데, 만약 내가 겪었다면 일부 개발자분들처럼 /etc/hosts에 hostname을 추가하거나, Public DNS server로 변경해서 장애를 해결할 생각을 해보았을까?