# Azure Everywhere the 1st wave

이전 회사에서 Microsoft partnership이 있어서 무료 credit으로 VM과 Database As Service로 mysql를 사용한 적이 있다. 그 이후로는 AWS service들만 heavy하게 사용해오고 있다. 몇 년동안 AWS seoul summit을 비롯해서 AWS devday, AWSKRUG 등에 참석하면서 AWS service들과 친해지도록 노력을 해왔다.

작년 2018년 라스베가스에서 열린 re:invent의 [keynote](https://youtu.be/ZOIkOnW640A?t=306)에서 IaaS market segment자료를 소개하였다. AWS market segment를 자랑하기 위한 자료였겠지만(AWS / 51.80%), 나에게 인상적인 것은 **Microsoft / 13.30%** 와 **Alibaba / 4.60%** 이었다. 
물론 폐쇄적인 중국 단일 시장이 엄청나게 크지만, Google이 Alibaba에게 밀린다는 것이 조금은 충격적이었다.

Azure의 Service들을 실제적으로 사용하지 않지만, Azure는 어떤 것을 강조하는지 들어보고자 Coex에서 열린 Azure Everywhere the 1st wave 행사를 참석하였다.

2018 AWS summit seoul에서 작년보다 AI, Machine learning에 큰 비중을 둔 것을 느낄 수 있었는데, 2019년 Azure conference도 AI, data analysis가 큰 비중을 차지 한 것 같다.

하지만 나는 이번 Azure conference에서 Microsoft가 제일 강조한 점은 개발자를 위한 더 개방적인 회사로 진화하고 있다는 것이라 생각한다. 

### 개발자를 위해서 더 개방적인 회사로 진화

Keynote 발표에서 2014년부터 2018년까지 년도별로 Azure가 Kubernetes, PostgreSQL, MySQL, Apache Spark, Linux, Nodejs등과 함께 어떤 행보를 이어갔는지 보여줬다.

> 불과 얼마 부터 우리가 취했던 행동, 그리고 현재의 행동 미래의 행동으로 Microsoft를 판단해야 합니다.

Microsoft CEO Satya Nadella가 인터뷰에서 말한 내용을 인용을 하면서 기존의 폐쇄적인 이미지를 탈피하고자 노력하는 것을 느꼈다.

특히 Github이 최근 private repo도 모든 개발자에게 푼 것도 언급하였다. Github관련 Keynote 세션이 두번 째로 있었는데, Github이 Open source와 개발자들에게 얼마나 영향을 미쳤는지 설명하였다.
Github의 이미지를 Azure와 연결하고자 한것 같다. Github과 Azure의 integration으로 Microsoft의 브랜드 이미지를 개선하고, Azure의 마켓을 넓혀갈려는 의지가 느껴졌다.

다음으로 Apache spark & Azure databricks 세션이 있었다. **The other 99% struggle with AI**이라고 설명하는 부분에서는 일부 소수 기업만 AI를 잘 사용하고 있다고 말하면서, databricks와 같은 서비스들이 AI의 대중화를 가져올 수 있다고 말했다. 

Github, Apache spark를 keynote에서 비중있게 다룸으로써 Microsoft가 Opensource에 더 관대하고 개발자를 위해 진화해가고 있다는 것을 전달했다고 생각한다.

---

### 기억에 남는 부분

#### More time innovating

> Top performing software companies spend more time innovating and less time on rework

> On average developers spend 48% of their time writing source code.

우리는 얼마나 rework가 아닌 innovation을 위한 것에 시간을 쓰고 있을까?
어떻게 DevOps engineer로 개발자들이 좀 더 코드를 작성하는데 시간을 할애할 수 있도록 어떤 support를 하면 좋을까?

#### Azure function & Websocket

Azure function에는 Python이 preview이다. Azure에서는 S3같은게 blob storage인것 같은데 최근에 static web hosting을 할 수 있게 되었다고 한다. Azure function에서 Binding이 있어서 I/O에 대한 코드를 작성할 필요가 없다. cosmosDB에 query를 넣어서 return을 줄수 있도록 Binding하는 기능이 있어서 신기했다. AWS lambda에도 binding같은 것이 있으면 편리하겠다는 생각이 들었다.

그리고 Azure SignalR service를 소개했는데, 예전에 data를 보여주는 간단한 웹을 만들 때 signalR로 websocket 열어서 받았던 적이 생각났다. Azure에서는 Azure SignalR service에 Azure function을 달아서 쉽게 실시간 채팅앱을 만드는 것이 흥미로웠다.

**그럼 AWS에서 어떻게 이런 채팅앱을 쉽게 만들 수 있을까 궁금해졌다.**

[AWS API gateway에 websocket API를 추가하였다.](https://aws.amazon.com/blogs/compute/announcing-websocket-apis-in-amazon-api-gateway/) 그래서 AWS에서 실시간 채팅 앱같은 걸 만들기 참 쉬워졌다. API gateway를 websocket API로 만들고 action에 따라서 lambda를 연결해주면 쉽게 만들 수 있다. AWS 블로그에서 설명한대로 쉽게 따라 해볼 수 있었다. wscat node모듈로 테스트해보니 잘 작동하였다. 

#### software가 기업에게 점점 중요해지고 있다.

Fortune 500 회사중에 Industry distruption으로 50%가 없어졌다.

> In order to compete, every company is becoming a software company

John deere같은 회사에도 1000 이상의 개발자 있어 Software driven이다. 

#### 역시 차세대 Orchestration tool은 K8S

Azure에도 Kubernetes managed service로 AKS를 제공하고 있다. 첫번 째 Keynote에서 Kubenetes가 Orchestration tool를 리딩할거라 말하는 부분도 있었다.
Microservice관련 세션에도 Azure에서 AKS에 투자를 많이 하는 것을 들을 수 있었다. AWS에서도 K8S를 위한 managed service인 EKS가 있고, 앞으로 K8S에 더 많은 관심을 가져야 겠다.