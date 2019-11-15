# Google Web Master

4월 30일 구글 스타트업 캠퍼스에서 진행되는 Google Webmaster Conference를 다녀왔었다. 참석해서 적어놓았던 내용들을 정리해서 올린다고 미뤄뒀던 것을 이제서야 정리해서 올리게 되었다. 그래도 적어 놓았던 내용들이 있어서 그때 내가 어떤 것을 느끼고 생각했는지 다시 한 번 떠올릴 수 있었다.

## How Search Works

첫 번째 세션은 화상채팅으로 DongHwi Lee님이 Web crawler에 대한 기초적인 설명을 해주셨다. Web crawler는 새로운 문서 발견하고 업데이트하는 중요한 목적을 가진다. crawler가 crawling하고 Index 정리하고 알고르짐으로 검색되는데, 일 년에 500개의 새로운 알고리즘이 적용되서 실험된다고 한다. 알고르즘이 계속 바뀌기 때문에 구글개발자도 전체를 알기도 설명하기도 어렵다고 한다.

- 모바일, 웹브라우저, 탭에서 검색결과가 다르다.
- 모바일에서 더 빠르게 제공될 수 있는 검색결과가 더 우선시 된다.
- 홈페이지 subsection.

🤔🤔우리 회사를 쳤을 때 충분한 정보를 보여주는 snippet과 subsectioin을 보여주지 않는다. 

- Dynamic하게 바뀌었는데, 검색엔진도 사용자처럼 이해하는게 필요해졌다. Web rendering service. google bot도 chrome처럼 브라우저에서 사용자가 보는것처럼 봐서 이해하려고 한다.
- Allow Googlebot to access CSS, Javascript, Images, XMR
- AMP도 설명하셨다.
- 지원하는 브라우저 limit 말고는 성능적으로 모든 브라우저에 적용될 수 있고, AMP를 쓴다고 검색 결과에 Rank에 영향을 미치지는 않는다. (🤔🤔근데 모바일에서는 더 빠르게 제공될 수 있는 검색결과가 우선시 된다고 했는데?)

## Global Trends in Google Search

Focus on your users

20% of searches in the Google App are now by Voice

더이상 user들이 keyword로 검색하지 않고, 문장(자연어)으로 요청한다.

70% of requests to the Google assistant are expressed in natural language

https://search.google.com/search-console/welcome

### 질문

#### Q1 site colon

rough approximation based on google found. interpolation

#### Q2 자연어로 검색하는 트렌드가 한국에서도 같은 트렌드가 있을지? 

A global이고 모든 나라가 아니고, 수치에 포함되어 있는 나라가 한국이다.

tips to prepare for better google search with voice
A webmaster guide라인을 따라라. tag를 친구나 교수님한테 얘기하는 것처럼 달아라.(keyword가 아니라)

#### Q3 천 만개 페이지가 수집. Crwaling limit 관련해서.. crawling limit을 넘는지?? 필요한 컨텐츠만 크롤링 될 수 있게 URL정리하거나 페이지를 정리해야하는지?

site마다 다르기 때문에 limit이 걸렸는지 모르겠다. 하지만 천 만개는 커버가 될 것 같다. limit을 걱정해서 할 필요는 없을 것 같고, user를 위해서 link structure. sitemap, speed up website

#### Q4 Page rank를 할 때, 서비스의 스피드를 높이고 할 수 있는데, Rank관련 우리가 할 수 있는게 한계가 있다. 기존에 external link가 많거나 이미 유저들이 선호했던 사이트를 Rank를 이길 방법이 있는지?

A possible. main factor is relevant. 유저의 쿼리와 유사성이 핵심이다. 그다음 퀄리티 links수.

## Make Better Websites for Your Users

검색엔진의 factor와 알고르즘이 계속 변화하기 때문에, 구글러도 어떻게 검색엔진에서 high rank되는 정확히는 모른다.

검색 최적화 : 쉽게 수집하고 색인할 수 있게

### robot.txt : 검색엔진의 트래픽을 조절하는 용도

robot.txt : 검색엔진의 트래픽을 조절하는 용도

한국에서는 bot이랑 세큐리티와 연관되었다고 생각하고 막는 경우가 흔하다. 그런데 이렇게 막아놓는 경우가 있다.

```
Disallow:/css/
Disallow:/*.js
Disallow:/images/
```

google bot이 rendering해서 frame가 어떤지 이미지가 뭔지 파악할수가 없다.

내부 검색 엔진 페이지. 사용자에게는 필요하지만 검색엔진에게는 필요없다. 이럴 경우에는 `Disallow: /search/`라고 하면 불필요하게 트래픽이 오지 않게.

### 기본적인 Tips

"" 안에 검색은 안에 있는 내용이 정확하게 있는 사이트를 검색

검색엔진의 제목 <title> tag 몇십년 변하지 않는

meta name="description"

bookmark할 때도 title를 가져오고 title대부분은 회사명을 적었는데, 회사명이 충분히 유명하지 않다면 페이지의 내용을 파악할 수 있도록 하는 방법으로

ex) 워크넷 - 믿을 수 있는 취업 포털

나쁜 예

모든 페이지에 같은 title과 description metadata가 들어가 있다. 검색하면 다 똑같은 설명이 나온다. 페이지별로 title, description을 설정. description이 없어도 구글봇이 내용을 가져와서 보여주는데 정확하지 않을 수 있기 때문에 description을 계속 사용하는 걸 추천

최대한 텍스트로 해서. 나쁜 예로 과거 상품설명을 이미지로.
🤔🤔 근데 생각해보면 우리 MD상품 설명도 다 그림으로. 콘서트 설명도 대부분 이미지로 해서 하고 있다.

img tag에 이미지 명을 어떤 것이다 file명을 하는 거라 alt에서 이미지 설명

https://search.google.com/search-console/welcome

link nofollow 댓글이나 이런데서 링크를 스팸에서 할 수 있는 걸 방지

g.co/recaptcha/v3

### 질문

#### Q1 Alt

accessiblity를 위해서 있는 속성이었기 때문에 서술형으로 해도 좋을 것 같다.

#### Q2 이미 스팸으로 오염된 페이지는 nofollow를 했을 때 다시 복구가 되는지?

이미 오염된 페이지가 복구는 안되고 google search console등을 통해서 이제 스팸이 없다고 알려주는게 방법이 있다.

우리도 지금 url이 uuid로 되어 있는데,
이것도 url로도 페이지를 파악할 수 있게 URL

이번 저번 세션은 기초적이지만 실제로 적용이 많이 안되고 있는 것들

canoical로도 중복된 페이지 정리

링크의 올바른 활용

앵커 텍스트

다국어 지원

<link rel="alternate" hreflang="ko" href="https://www.example.com">
<link rel="alternate" hreflang="en" href="https://en.example.com">

https 검색 순위에 적용된다.

HTTPS as a ranking signal => http만 유지하고 있으면 검색에 불리해지는 것

예제에서 https://에서 image가 http://로 로딩되는 상황에서 warning이 나온다. ref //example.com으로 하는 tip

ssllabs.com 사이트에 보안 설정이 잘되어 있는지 확인가능

Mobile first indexing

g.co/mobilefriendly

모바일 검색에서 제외 될 수가 있다.

mobile first indexing

google optimizer

구조화된 

웹개발자채용
🤔🤔 로켓펀치에 있는 채용공고도 파트너가 아니다. 마크업? 추가해주면 채용공고가 여기에 나올 수 있다??

wikipedia에 연결될 수 있게?

Q&A F&Q How-to 이것도 마크업하면 바로 나오게 할 수 있다.

이렇게 markup 작업한게 Assistant에 활용될 수도 있다. (지금은 아직 활용이 별로 되고 있지 않지만)

## Site Quality

All the structured data feature

Structured data testing tool (실제와 조금은 다르게 나올 수 있어서 먼저 이 tool에서 잘나오게 하고 실제에서 한번 더 테스트 필요)

mobile friendly test

robot.txt설정되고 해서 막으면 에러 날 거다.

여기서 보이는 view 구글 검색해서 본 view이다.

AMP pages test tool

## Speed tool

## Field Data

Chrome user experience report (big query에 데이터 정리 해놓은게 있네.)

Lighthouse

## Lab Data

performance budget

A/B

https://winonmobile.withgoogle.com/

https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fwww.mymusictaste.com
https://www.google.com/search?source=hp&ei=KfDHXITPJ6OmmAWHiIWAAw&q=%EC%9B%B9%EA%B0%9C%EB%B0%9C%EC%9E%90+%EC%B1%84%EC%9A%A9&oq=%EC%9B%B9%EA%B0%9C%EB%B0%9C%EC%9E%90+%EC%B1%84%EC%9A%A9&gs_l=psy-ab.3...1597.6975..7092...12.0..1.228.2556.5j10j4......0....1..gws-wiz.....0..0i131j0.U2NsDEZ0obs&ibp=htl;jobs&sa=X&ved=2ahUKEwjmsPWGnffhAhUQMN4KHaDmD9AQiYsCKAF6BAgJECo#fpstate=tldetail&htidocid=6MJvyAAlbVmNN9HYAAAAAA%3D%3D&htivrt=jobs
https://search.google.com/test/mobile-friendly?utm_source=gws&utm_medium=onebox&utm_campaign=suit&id=Obup5adIVww6p7k5yIhJMw

https://winonmobile.withgoogle.com/