import SwiftUI

struct MarathonEvaluateView: View {
    let audioFileURL: URL?
    let textFileURL: URL?
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    let repetitions: Int
    
    @ObservedObject var tabManager: TabManager
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    @StateObject private var evaluateSpeechContent: EvaluateSpeech_content
    @StateObject private var speechManager = SpeechManager()
    
    @State private var evaluationResult: ProcessedEvaluationData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isNavigatingToMarathonDecideTheme = false
    @State private var isNavigatingToEnd = false
    
    @State private var themeCheckResult: String?
    @State private var isThemeChecking = false
    @State private var themeCheckError: String?
    
    @State private var timer: Timer?
    @State private var remainingTime = 120
    
    @State private var isExitNavigationActive: Bool = false
    
    @State private var totalScore: Int?
    
    @State private var isPronunciationEvaluated = false // 発音評価が終了したことを教えるフラグ
    @State private var isContentEvaluated = false // 内容評価が終了したことを教えるフラグ
    
    init(audioFileURL: URL?, textFileURL: URL?, tabManager: TabManager, themeManager: ThemeManager, favoriteTopicsManager: FavoriteTopicsManager, repetitions: Int, repetitionManager: RepetitionManager, scoreManager: ScoreManager, logScoreManager: LogScoreManager) {
        self.audioFileURL = audioFileURL
        self.textFileURL = textFileURL
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.favoriteTopicsManager = favoriteTopicsManager
        self.repetitions = repetitions
        self.repetitionManager = repetitionManager
        self.scoreManager = scoreManager // Initialize ScoreManager
        self.logScoreManager = logScoreManager
        _evaluateSpeechContent = StateObject(wrappedValue: EvaluateSpeech_content(conversationManager: ConversationManager(apiKey: Config.openai_apiKey)))
    }
    
    var body: some View {
        
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    NavigationLink(destination: ContentView()
                        .navigationBarBackButtonHidden(true), isActive: $isExitNavigationActive) {
                            EmptyView()
                        }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WPM(Words Per Minute)")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        if let wpm = evaluateSpeech.evaluate_wpm(audioFileURL: audioFileURL, textFileURL: textFileURL) {
                            Text("今回のWPMは \(Int(wpm))です。")
                                .padding(.leading, 10)
                        } else {
                            Text("WPMの計算に失敗しました")
                                .padding(.leading, 10)
                        }
                        
                        Text("参考：")
                            .padding(.leading, 10)
                        
                        let references = [
                            "・日本人平均：90-110",
                            "・ネイティブ平均：200-250",
                            "・既知の話題に関するプレゼン：130-160",
                            "・新規話題に関するプレゼン：100-130"
                        ]
                        
                        ForEach(references, id: \.self) { reference in
                            Text(reference)
                                .font(.subheadline) // フォントを小さく
                                .padding(.leading, 10)
                        }
                        
                        Divider()
                        
                        Text("Pronunciation and Fluency")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        if isLoading {
                            ProgressView("評価中...")
                                .padding(.leading, 10)
                        } else if let evaluationResult = evaluationResult {
                            Text("評価された単語:")
                                .font(.headline)
                                .padding(.leading, 10)
                            buildColoredText(from: evaluationResult.wordScoreList)
                                .padding(.leading, 10)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("採点結果")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                HStack {
                                    Text("Pronunciation:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.speechacePronunciation))点")
                                }
                                HStack {
                                    Text("Fluency:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.speechaceFluency))点")
                                }
                            }
                        } else if let errorMessage = errorMessage {
                            Text("エラー: \(errorMessage)")
                                .padding(.leading, 10)
                        } else {
                            Text("評価を行うには音声ファイルとテキストファイルを提供してください。")
                                .padding(.leading, 10)
                        }
                        
                        Divider()
                        
                        Text("Content")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        if isThemeChecking {
                            ProgressView("テーマをチェック中...")
                                .padding(.leading, 10)
                        } else if let themeCheckResult = themeCheckResult {
                            Text(themeCheckResult)
                                .padding(.leading, 10)
                        } else if let themeCheckError = themeCheckError {
                            Text("エラー: \(themeCheckError)")
                                .padding(.leading, 10)
                        } else {
                            Text("評価データがありません。")
                                .padding(.leading, 10)
                        }
                        
                        if let totalScore = totalScore {
                            Text("総合スコア: \(Int(totalScore))/200点")
                                .padding(.leading, 10)
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            
                        } else {
                            Text("総合スコアを計算中...")
                                .padding(.leading, 10)
                        }
                        
                        
                        Text("残り時間: \(remainingTime)秒")
                            .padding(.leading, 10)
                            .foregroundColor(.red)
                        
                        if repetitionManager.repetitionCount < repetitions {
                            Button("テーマ生成に戻る") {
                                isNavigatingToMarathonDecideTheme = true
                                timer?.invalidate()
                            }
                            .padding(.leading, 10)
                        } else {
                            Button("マラソンモードを終わる") {
                                isNavigatingToEnd = true
                                timer?.invalidate()
                            }
                            .padding(.leading, 10)
                        }
                        
                        NavigationLink(destination: MarathonDecideThemeView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, favoriteTopicsManager: favoriteTopicsManager, themeManager: themeManager, repetitions: repetitions).navigationBarBackButtonHidden(true), isActive: $isNavigatingToMarathonDecideTheme) {
                            EmptyView()
                        }
                        .navigationBarBackButtonHidden(true)
                        NavigationLink(destination: EndView(scoreManager: scoreManager, logScoreManager: logScoreManager).navigationBarBackButtonHidden(true), isActive: $isNavigatingToEnd) { EmptyView() }
                    }
                    .padding()
                    .onAppear {
                        repetitionManager.repetitionCount += 1
                        fetchPronunciationEvaluation()
                        checkThemeWithChatGPT()
                        startTimer()
                    }
                }
                .padding()
            }
            .background(Color.clear)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Report")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(trailing: Button("終了") {
                isExitNavigationActive = true
            })
        .background(
            Image("back") // 画像名に応じて変更
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
        )
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            remainingTime -= 1
            if remainingTime == 0 {
                timer?.invalidate()
                // Navigate to the correct view after the timer expires
                if repetitionManager.repetitionCount < repetitions {
                    isNavigatingToMarathonDecideTheme = true
                } else {
                    isNavigatingToEnd = true
                }
            }
        }
    }
    
    private func checkThemeWithChatGPT() {
        guard let textFileURL = textFileURL else {
            themeCheckError = "テキストファイルがありません。"
            return
        }
        isThemeChecking = true
        evaluateSpeechContent.checkTextAgainstTheme(textFileURL: textFileURL, decidedTheme: themeManager.DecidedTheme) { result in
            DispatchQueue.main.async {
                isThemeChecking = false
                if let result = result {
                    self.themeCheckResult = result
                    self.isContentEvaluated = true
                    self.calculateTotalScoreIfNeeded()
                } else {
                    self.themeCheckError = "ChatGPTからの応答がありませんでした。"
                }
            }
        }
    }
    
    private func fetchPronunciationEvaluation() {
        guard let audioFileURL = audioFileURL, let textFileURL = textFileURL else {
            errorMessage = "音声ファイルまたはテキストファイルがありません。"
            return
        }
        isLoading = true
        evaluateSpeech.evaluatePronunciationAndProcess(audioFileURL: audioFileURL, textFileURL: textFileURL) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let processedData):
                    self.evaluationResult = processedData
                    self.isPronunciationEvaluated = true
                    self.calculateTotalScoreIfNeeded()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isPronunciationEvaluated = true
                }
            }
        }
    }
    
    private func calculateTotalScoreIfNeeded() {
        if isPronunciationEvaluated && isContentEvaluated {
            let contentScore = evaluateSpeechContent.calculateTotalScore() ?? 0
            let pronunciationScore = evaluationResult?.speechacePronunciation ?? 0
            let fluencyScore = evaluationResult?.speechaceFluency ?? 0
            self.totalScore = contentScore + Int((pronunciationScore + fluencyScore) / 2)
            
            // ScoreManagerに保存
            if let score = self.totalScore {
                self.scoreManager.addScore(score)
            }
        }
    }
    
    private func color(for qualityScore: Double) -> Color {
        switch qualityScore {
        case 80...100:
            return .green
        case 70..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func buildColoredText(from wordScoreList: [WordScore]) -> Text {
        var coloredText = Text("")
        for wordScore in wordScoreList {
            let wordWithColor = Text(wordScore.word + " ")
                .foregroundColor(color(for: Double(wordScore.qualityScore)))
            coloredText = coloredText + wordWithColor
        }
        return coloredText
    }
}

