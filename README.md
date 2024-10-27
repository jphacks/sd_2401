# EGOイスト

|<img width="250" alt="Screenshot 2024-10-27 at 23 54 19" src="https://github.com/user-attachments/assets/bde8e8eb-3fe7-4bc7-ba71-ebdb0a39801e">|<img width="250" alt="Screenshot 2024-10-27 at 23 58 23" src="https://github.com/user-attachments/assets/99bbf964-85e5-4cb6-ae75-01b97f3ce58d">|<img width="250" alt="Screenshot 2024-10-27 at 23 58 56" src="https://github.com/user-attachments/assets/ff0a6261-a7f3-4b7e-89b6-f40ba6253742">|

|<img width="250" alt="Screenshot 2024-10-28 at 0 07 36" src="https://github.com/user-attachments/assets/e70ef802-a37e-48d0-9cd5-8dca522071b3">|<img width="250" alt="Screenshot 2024-10-28 at 0 09 44" src="https://github.com/user-attachments/assets/459c77d7-a5fd-4acb-bf4c-a76caad06522">|



## 製品概要
AIにはできないオリジナリティのあるスピーチを楽しく学習できるアプリ

### 背景(製品開発のきっかけ、課題等）
最も根本にあるきっかけは私達が今後国際学会で発表していく中で自分の「テーマに対して英語で論理的に説明する力」の不足を感じたことです。英会話アプリが世の中に多いのに対し、英語のスピーチを内容面、発音面の両面で評価するアプリは少ないです。また、既存のアプリは「日常会話」、「ビジネス」、「道案内」などの生活に関わるテーマを扱うことで英語学習を促進することを意図しているものの、例えば日常会話は一般に日常会話と言われている学校、家庭などの型にはまったテーマが多いです。このため、既存アプリの課題として以下の2つがあると考えました。
1. ある程度の長さのある英語のスピーチを論理的に行う力が身につかない
2. スピーチにオリジナリティを含める力（個人の体験や経験を含めた構成を行う力）が身につかない
3. テーマに親近感、面白みを感じず学習が継続しない

### 特長
#### 1. スピーチの個人の体験や経験を入れる力が身につきます
自分の好きなキーワードをもとにテーマを生成する「好きなテーマ」機能、自分の好きなYoutubeの動画を見て学習できる「Youtube」機能、自分の好きなニュースを検索して学習できる「news」機能があります。これにより自分の趣味や「本当の」日常の話題に関わるのスピーチを行うことで、スピーチに自然に個人の経験を入れられるようになります。これにより課題2を解決します。
#### 2. 自分に大きく関わる大好きなテーマや動画、ニュースでスピーチ練習ができます
特長1で書いた3つの機能は、自分の密接に関わるテーマ、動画、ニュースでスピーチ練習を行うための機能です。私達は何事も自分の好きなことなら継続して取り組めるのでこれにより課題3を解決しています。

#### 3. 特に内容面での評価を重視しています
テーマに関するスピーチ内容の一貫性評価、スピーチ構成の評価、スピーチに個人の体験がうまく組み込まれているかを評価、語彙、表現の多様性の評価を観点として重視しています。これによりユーザーに内容、論理構成がはっきりしていて、オリジナリティあるスピーチを行うよう促進します。これにより課題1, 2を解決します。

### 製品説明（具体的な製品の説明）
「好きなテーマ」モードでは、興味のあるテーマをいくつか入力し、テーマ生成ボタンを押すと、ChatGPTがそのテーマに基づいた多彩なトピックを提案します。気になるトピックを選び、マイクボタンを押してそのテーマについて話してみましょう。音声を提出すると、ChatGPTが内容や流暢さを分析し、改善点を丁寧にフィードバックします。
また、「YouTube」モードや「news」モードでは、自分の好きなコンテンツを見た後、その内容について話すことで、ChatGPTがさらに効果的な改善点を提供してくれます！


### 解決出来ること
上記課題1, 2, 3が解決できます。つまり、ユーザーの作る英語スピーチがもっと論理的に、かつAIにはできないもっとオリジナリティを含むものにすることができるはずです。さらに、自分の趣味や日常の延長線上に英語スピーチ練習をおけるので継続したいと思えるアプリになるはずです。

### 今後の展望
* 通信機能の実装により、他者と競争しあうことで学習意欲の向上を促す
* 通知機能などを駆使して、継続的な英語学習に取り組みやすくする
* メインコンテンツをスピーキング学習としながら、他の英語能力も学べるようにする
* 英語能力をRPGのようなスキルツリーやレート（あるいはレベル）として成長度を可視化すると共に、英語学習のゲーム化を目指して楽しく学べるようなアプリケーションにする
* また、スキルツリーによる可視化により、体系的な学習を可能にする
* Android版のアプリケーション開発

### 注力したこと（こだわり等）
* 自由なテーマの生成
* スピーチ内容の評価精度

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
* 

#### デバイス
* iPhone

### 独自技術
#### ハッカソンで開発した独自機能・技術

*テーマを自分の好きなキーワードから生成してそれをスピーチのテーマとするアイデア、機能
*自分の好きなYoutubeを検索できるようにしてその内容をもとにスピーチをするアイデアと機能
  

