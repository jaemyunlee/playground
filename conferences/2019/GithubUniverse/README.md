# Github Universe Keynote

Youtube로 Github Universe keynote day1과 day2를 보았다.

Github actions은 제한적으로 beta로 release 되었을 때부터 관심을 가지고 있었다. 서울에서 열린 Azure Everywhere Conference에서 Github의 Paul St. John분이 세션을 마치고 질문을 받었는데,  나는 손을 들고 Action이 현재 베타인데 언제 정식으로 release되어 사용될 수 있는지 물어봤었다. Product manager들은 빨리 된다고 하는데, 항상 늦어진다는 농담을 하면서 정확한 시기는 답변해주지 않았다. beta때 Action으로 테스트를 해보면서 빨리 정식 릴리즈되었으면 좋겠다고 생각하고 있었는데, 몇일 전 [드디어 GA가 되었다.](https://github.blog/changelog/2019-11-11-github-actions-is-generally-available/) 그리고 Kubernetes CI/CD를 조사하면서 ArgoCD를 테스트하게 되었는데, GitOps라는 컨셉을 처음 알게 되었다. 개발자들이 이미 Github 사용에 익숙하니깐 Github actions, checks, webhooks 그리고 ArgoCD를 활용하여 CI/CD를 구축하는 것을 계획했었다. 그래서 Github Universe Keynote가 Youtube에 올라오자 바로 클릭해서 보게 되었다.

## Github Actions!

Github Universe 2019에서 하이라이트 service는 Github actions인 것 같다. 내가 제일 많은 관심을 가지고 있던 서비스라 더 기억에 남았을 수도 있지만, Day1, Day2 keynote 연속으로 비중있게 Actions이 소개되었다. 

특히 Day2 keynote에서 AWS engineer가 ECS 서비스를 설명하고 Actions으로 deployment하는 것을 보여주는 것이 인상적이었다. Github이 Microsoft에 인수되면서 Azure와의 연동을 강조하지 않을까 생각했는데, 이렇게 AWS ECS에 배포하는 것이 keynote에 포함되었다는 것이 재미있었다. 

그리고 Github actions으로 Full requests에서 Terraform plan을 보여주고 deploy하는 것도 소개했는데, [Atlantis](https://github.com/runatlantis/atlantis) tool은 이제 정말 추억속으로 남을 것 같다는 생각이 든다. 😭

강연에서 Prometheus metric에 따라서 Github actions을 trigger한다는 식으로 설명했던 것 같았는데, [Actions Documents](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/events-that-trigger-workflows)을 보니깐 `repository_dispath`가 있다. 

> You can use the GitHub API to trigger a webhook event called repository_dispatch when you want to trigger a workflow for activity that happens outside of GitHub.

그리고 이것도 그전에 생각 안 해본건데, cron expression으로 event를 schdule를 할 수 있다. 

Github Actions가 GA가 되면서 Travis CI나 Circle CI는 시장에서 어떤 포지션을 잡을지 궁금하다.🤔

## Extras

### Github packages

NPM, Docker, Maven, RubyGems, NuGet...🤨 pip이 안보인다..

그래서 Github Ask에 Python Community도 큰데 왜 Github packages에 pip이 없는지 물어봤다. 그리고 추가될 계획이 있는지도. 반나절만에 답변이 왔다. 👍

> Thanks for reaching out. I'm happy to hear about your interest in GitHub Packages, we're really excited about the potential of this service.
We have an existing request to support the pip package manager currently sitting with our Product team for consideration and exploration; I've added your request as a +1 to this.
Over time we will be extending the offering of services and package sources we support with GitHub Packages.
We don't currently have an ETA on this, however you can keep an eye on the 
GitHub Changelog for future announcements on new features being added to the GitHub Packages.

Keynote day1에서 Packages를 찾아보고 pip이 없어서 아쉬웠고, 저렇게 Github에 문의까지 했었다. 하지만 Keynote day2를 보고 조금 이해는 갔다. 발표에서 npm packages는 3.5M projects가 의존하고 있고, RubyGems packages가 737K, Apache Maven packages가 94K, 그리고 pip가 78k가 있다고 설명한다. NPM, Maven, RubyGems가 packages에 먼저 포함된건 이해된다. 근데 NuGet은 있는데 pip이 없다니...🤨 NPM이 얼마나 활발한지 알 수 있었다.

### Mobile

Github에서 공식적으로 Mobile app은 출시하지 않을까 계속 의문이 있었는데, 드디어 Mobile app이 나오는구나! [Github for Mobile](https://github.com/mobile)에서 iOS로 신청했는데, 메일이 아직 안왔다. 언제 올려나? 🤩

> GitHub will send you a TestFlight invitation.

### Sponsor

이 부분도 상당히 신선했다. 인색하지 말고 나도 잘 쓰고 있는 오픈소스 프로젝트에 스폰으로 기여를 해봐야겠다. 

### Search

IDE에서 pull 받아서 보는게 귀찮아서, Web에서 코드 검색을 하는 경우가 많다. 띄어쓰기로 검색할 때 관련없는게 많이 나와서 불편했는데, 이점이 개선이 된다니 좋다.

### Asign Reviewer, Pull request reminder

현재 이러한 기능을 위해서 Pull Panda를 사용하고 있다. [Github에서 Pull Panda](https://github.blog/2019-06-17-github-acquires-pull-panda/)를 인수했었는데, Pull Panda에서 지원하는 기능을 이제 Github 자체에서 가능하게 하게하는 과정인가??🤔

### Security

이번 Conference에서 Actions 서비스 소개 다음으로 Security에 많은 비중을 둔 것 같다.

[Github Advisory Database](https://github.com/advisories)에서 pip ecosystem으로 검색해보니 Pillow, Django, Cryptography등의 volnerability등이 보인다.

**Denpendencies Graph**를 Enable을 하니깐 repo에서 의존하고 있는 Module들 리스크가 나왔다. 이렇게 의존하고 있는 모듈의 버전에 volnerability가 있으면 알람도 해준다고 한다. 좋다! 👍👍👍 devsecops...

Open source project가 아니고 기업에서 쓸려면 요금이 조금은 걸리지만, 이러한 Security관련 서비스가 있다는 것을 알았다. CodeQL은 Pricing이랑 정보 요청을 해봤다.

- [Semmle](https://semmle.com/lgtm) : CodeQL, LGTM 
- [hackerone](https://www.hackerone.com/)
- [whitesourcesoftware](www.whitesourcesoftware.com)

### Automated functional testing

[mabl](https://www.mabl.com/)