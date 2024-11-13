# EIGOイスト
自分の好きなモノをもとに楽しく英語スピーキングを学習できるアプリ、 **EIGOイスト** 
<img width="830" alt="Screenshot 2024-10-28 at 5 46 54" src="https://github.com/user-attachments/assets/2f35d373-fc53-4db7-bb27-c941d271a461">


## デモ動画
[こちら](https://youtu.be/5FQa3x18Aqk)からデモ動画をご覧いただけます。

## 製品概要
### 背景(製品開発のきっかけ、課題等）
英語の学習習慣、特にスピーキングの学習習慣がまったく身につかない学生生活が義務教育時代から続いています。また、「英語勉強は楽しくないモノ」という認識をしている人が世の中にも多いのではと考えています。
これによって義務教育によって強制的に学習させられるリーディングばかり伸びていくのに対し、スピーキングは強制されないし楽しくもないから勉強しなくなるのでできるようにならないという問題が生まれます。将来的に英語を「自分を表現するツール」として使うためにはスピーキングが最も重要なのにも関わらず、です。
この問題を解決するために、まずは楽しく継続して学習できるスピーキングアプリを開発しようと考えました。

私達は「自分の好きなことで勉強するのは楽しい」という考えをもとにスピーキングアプリの開発を行ってきました。実際、私達が熱を持ってここまで開発を行ってこれたのも、自分たちがプログラミングやアプリ開発が好きだからです。そのため、私達は従来の英語アプリのようなビジネス・日常会話・道案内などの型にはまった退屈なテーマでスピーキングを学ぶのではなく、むしろ自分のエゴに従い、自分の趣味の延長にある好きなコンテンツでスピーキング練習できるアプリ「EIGOイスト」を開発しました。

#### 課題
以上の背景を踏まえて、下記の3つの課題を分析し、アプリの「特長」を開発していきました。
1. 既存アプリはテーマに親近感、面白みを感じないので楽しくない
2. スピーキングの学習にそもそもモチベーションがない
3. 既存アプリの題材は自分の生活や趣味に関わらないので、自分の体験をスピーチに入れにくい。このせいでユーザーのスピーチの表現力が向上しない

### 対象ユーザー
#### 日本人
#### 全年齢の英語学習者
#### 特に、英語学習を継続していきたい多趣味な人
#### Youtube、ニュースを見るのが趣味だけど勉強しないことに罪悪感を感じてしまっている英語学習者
　
より多くの英語学習者がこのアプリの対象ユーザーになってもらうために、後の説明の通りたくさんの機能を作りました。機能ごとの対象ユーザーは製品説明に書いてあります。


### 特長

#### 1.自分に大きく関わる大好きなテーマや動画、気になるニュースでスピーキング練習ができます
このアプリには、自分の好きなキーワードをもとにテーマを生成する「好きなテーマ」機能、自分の好きなYoutubeの動画を見て学習できる「Youtube」機能、自分の好きなニュースを検索して学習できる「news」機能、自分の好きな画像を入力してそれをもとにテーマを生成する「画像テーマ」機能があります。
自分の生活や趣味志向を素材として生成されたテーマを話す楽しさ、スピーチのテーマ、シチュエーションを自分でカスタマイズする楽しさを提供します。

#### 2. スピーチの内容面での評価にもこだわっています
「マラソンモード」という機能の中で過去のスコア(=自分の努力)の可視化、過去の平均スコアと直近のこの機能による学習の継続率によって金、銀、銅、青のランクが決まるシステムの導入、ランクやスコアが向上した喜びを友達と分かち合うSNS共有の実装を行っています。これにより競技性やランクが上がること、日々の頑張りを共有することによるモチベーションや楽しさを提供します。

#### 3. スピーチに個人の体験や経験を入れる力が身につきます
自分の生活や趣味をスピーチの題材とすることで、ユーザーはスピーチにより詳細な具体例や経験を含みやすくなります。また、スピーチの内容評価部分で構成や表現の多様性やスピーチの独自性を重視することでユーザーが具体例や経験の入ったスピーチをすることをプラスに評価します。これにより、ユーザーはより具体性の高いスピーチを構成を意識して行う力が身につき、表現力が向上します。

### 製品説明（具体的な製品の説明）
取り組みやすいたくさんの機能を実装したので、自分にあった形で、楽しく効果的にスピーキングを勉強できます。 このアプリでは「好きなテーマ」モード、「Youtube」モード、「News」モード、「画像テーマ」モードの4つのスピーチテーマ生成コンテンツを提供しています。
それぞれのモードでは、「興味のあるモノ」(好きなテーマ、Youtube動画の内容、ニュース記事の内容、好きな画像)がテーマ生成のもととなっていて、テーマ生成ボタンを押すと、ChatGPTが 「興味のあるモノ」 に基づいた複数の多彩なスピーチテーマを提案します。 その後、気になるスピーチテーマを選び、マイクボタンを押してそのテーマについて話してみます。 最後に、その音声を提出すると、ChatGPTが内容や流暢さを分析し、改善点が丁寧にフィードバックされます！

また、これら4つの機能に競技性を持たせたモードとして「マラソンモード」を開発しました。

各モードごとの具体的な動作の流れは、以下で説明します。

### 1.好きなテーマ
#### 1.1. 好きなワードを入力します。
#### 1.2. 好きなワードに対してテーマ生成をして、複数のスピーチテーマから最も話したいテーマを選びます。テーマ横の電球ボタンを押すことでヒントを生成してくれます。
#### 1.3. マイクボタンを押して選択した「最も話したいテーマ」に関するスピーチを行い、音声を提出すると、評価が得られる。評価では、WordPerMinute、発音と流暢さ、話した内容の独自性、発音のチェック、模範解答等を分析＆採点しています。

#### ＜対象ユーザー＞
・自分の好きなことならたくさん話せる人
・動画、ニュース等を介さないシンプルなスピーキング練習をしたい人

|<img width="250" alt="Screenshot 2024-10-28 at 0 26 22" src="https://github.com/user-attachments/assets/d322c3e1-4d85-4d55-8690-d6569c8dcd33">|<img width="250" alt="Screenshot 2024-10-28 at 0 27 01" src="https://github.com/user-attachments/assets/2efe477c-049d-476f-99d2-1e442b2f7f31">|<img width="250" alt="Screenshot 2024-10-28 at 0 33 56" src="https://github.com/user-attachments/assets/30bcdb10-7cfa-4642-92bd-2b121d701cae">|<img width="250" alt="Screenshot 2024-10-28 at 0 36 08" src="https://github.com/user-attachments/assets/a7c71165-aad2-47ee-b111-11a1f9c3ee97">|<img width="250" alt="Screenshot 2024-10-28 at 0 35 07" src="https://github.com/user-attachments/assets/d8c195ba-1822-495a-b1d7-ec92cf7a3a53">|

### 2.Youtube
#### 2.1. 見たい動画の検索ワードを入力し検索し、複数の動画が提案されるので最も見たい動画を選択する。(ダブルタップすることで動画をアプリ内で簡単に見られる。)
#### 2.2. マイクボタンを押して選択した動画に関するスピーチを行い、音声を提出すると、評価が得られる。
|<img width="250" alt="Screenshot 2024-10-27 at 23 54 19" src="https://github.com/user-attachments/assets/bde8e8eb-3fe7-4bc7-ba71-ebdb0a39801e">|<img width="250" alt="Screenshot 2024-10-27 at 23 58 23" src="https://github.com/user-attachments/assets/99bbf964-85e5-4cb6-ae75-01b97f3ce58d">|<img width="250" alt="Screenshot 2024-10-27 at 23 58 56" src="https://github.com/user-attachments/assets/ff0a6261-a7f3-4b7e-89b6-f40ba6253742">|<img width="250" alt="Screenshot 2024-10-28 at 0 07 36" src="https://github.com/user-attachments/assets/e70ef802-a37e-48d0-9cd5-8dca522071b3">|<img width="250" alt="Screenshot 2024-10-28 at 0 09 44" src="https://github.com/user-attachments/assets/459c77d7-a5fd-4acb-bf4c-a76caad06522">|


### 3.News
#### 3.1. 興味のあるワードを入力し、検索ワードにヒットする最近の人気なニュースを検索します。
#### 3.2. 提案されたニュースを一つ選択することで、スピーチテーマを生成します。(選択したニュースの左下を押すことで、ニュースをSafari等のブラウザで見れます)
#### 3.3. 3.2でテーマを選択した後に、マイクボタンを押して選択したテーマに関するスピーチを行い、音声を提出すると、評価が得られる。この評価は、ChatGPTに記事の内容の全文を送ることによって精度の高い評価を実現しています。
|<img width="250" alt="Screenshot 2024-10-28 at 0 17 39" src="https://github.com/user-attachments/assets/d6070bad-2830-4951-8384-efc7d0e20aa5">|<img width="250" alt="Screenshot 2024-10-28 at 0 18 53" src="https://github.com/user-attachments/assets/50a6b82d-b441-4eac-8a09-6e9c44ce7066">|<img width="250" alt="Screenshot 2024-10-28 at 1 13 05" src="https://github.com/user-attachments/assets/b77a83b4-c216-4bbb-904f-b6e54da5e2fb">|<img width="250" alt="Screenshot 2024-10-28 at 0 22 29" src="https://github.com/user-attachments/assets/2d003cc6-6b3d-4ca2-a324-85c4fe0d2bbf">|<img width="250" alt="Screenshot 2024-10-28 at 0 09 44" src="https://github.com/user-attachments/assets/42d395c3-edd5-4e24-9223-31404a3084b7">|


### 解決出来ること
まず一番は楽しく勉強をすることができるので、学生から大人まですべての英語学習者が楽しく継続的に英語スピーチ練習を学ぶことができます。
また、それぞれのモードを設定したのは、以下を解決することを目的にしているからです。

* 「好きなテーマ」モードでは、好きなテーマを融合させたテーマを生成して、他では見られない **「自分の好きが詰まったユニークなテーマ」** に対してスピーキングをするモードです。
* 「Youtube」モードでは、欲に負けてYoutubeを見る人でも、その内容をすぐにスピーキングでアウトプットすることで新たな勉強の流れを作っています。
* 「News」モードでは、リアルの時事問題を生かしてテーマを生成するので、長い時間英語学習をすることで社会情勢がわからくなることを防ぎ、むしろニュースを読む習慣を提供しています。

このように自分の趣味や日常の延長線上に、英語スピーチ練習をすることが可能なので継続性の高い英語スピーキング学習アプリになっています。

音声認識にWhisperとSpeechace APIを用いたので、高精度の発音分析による１人では見つけにくい発音ミスの指摘を可能にしています。
加えて、スピーチの内容が当たり障りのないものではなく、独自性(ニュースであれば関連知識ではなく、ニュースの本文の内容を話しているか等)があるかを採点することで、真面目に取り組む習慣も促進しています。

### 今後の展望
* より集中的に学習を行える「マラソンモード」の実装。具体的には今回開発した「好きなテーマ」、「Youtube」、「News」の機能の1つ1つに制限時間を設け、ユーザーが設定した回数分繰り返すことにより、何度もフィードバックをもらいながらどんどんスピーチの中身を良くしていく仕組みの実装。さらに点数を毎回記録することで自分の点数の推移をグラフ化し、ユーザーに成長を実感させる。
* 通信機能の実装により、他者と競争しあうことで学習意欲の向上を促す
* 通知機能などを駆使して、継続的な英語学習に取り組みやすくする
* メインコンテンツをスピーキング学習としながら、他の英語能力も学べるようにする
* 英語能力をRPGのようなスキルツリーやレート（あるいはレベル）として成長度を可視化すると共に、英語学習のゲーム化を目指して楽しく学べるようなアプリケーションにする
* また、スキルツリーによる可視化により、体系的な学習を可能にする
* Android版のアプリケーション開発
* まとめると、さらに楽しく、成長を実感できるアプリにしたいです！

### 注力したこと（こだわり等）
* ワードを融合させて融合させてユニークで面白いテーマの生成
* WhisperとSpeechace APIを用いた音声認識精度の向上と、取得した音声テキストを用いてスピーチ内容の評価精度を向上させたこと
* 多くのユーザーにリーチするための副次的な目的が異なる3つのモード(楽しく簡単に学べる"好きなテーマ"モード、動画を見た延長線上で学ぶための"Youtube"モード、最新を学ぶための"News"モード)の実装

## 開発技術
### 活用した技術
#### API・データ
* Open API(ChatGPT, Whisper)
* Youtube API
* Speechace API
* News API 

#### フレームワーク・ライブラリ・モジュール
* SwiftUI
* SwiftSoup
* SDWebImageSwiftUI

#### デバイス
* iPhone(iOS18.0以降でデモをした)

### 独自技術
#### ハッカソンで開発した独自機能・技術

* テーマを自分の好きなキーワードから生成してそれをスピーチのテーマとするアイデア、機能
* 自分の好きなYoutubeを検索できるようにしてそのタイトルをもとにスピーチをするアイデア、機能
* ニュースのHTMLが長すぎて処理がうまくいかなかったり時間がかかりすぎる問題を、HTMLのニュース形式がバラバラであるが多くで共通の<p>タグによってスクレイピングすることで関数部分を除外し、ChatGPTが処理できるトークン数に収めることができることに気づき処理した機能

* これらを頑張ったことでユーザーが自分だけにしかできないスピーチを構成し、発表させ、それを評価できるシステムが、何よりも楽しい学習方法で構築できたことが一番の独自機能だと感じています。 

*高精度音声認識＆独自評価基準を開発した、commit_idのeaee9d9が力を入れた実装になります。
  

