import SwiftUI

struct EvaluateView: View {
    // audioFileURL と textFileURL を引数として受け取る
    let audioFileURL: URL?
    let textFileURL: URL?
    let decidedTheme: [String]
    
    // EvaluateSpeech のインスタンスを持つ
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    // EvaluateSpeech_content のインスタンスを持つ
    @StateObject private var evaluateSpeechContent: EvaluateSpeech_content
    
    // 評価結果を保持するための状態変数
    @State private var evaluationResult: ProcessedEvaluationData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // ChatGPTからのテーマ一致結果
    @State private var themeCheckResult: String?
    @State private var isThemeChecking = false
    @State private var themeCheckError: String?
    
    init(audioFileURL: URL?, textFileURL: URL?, decidedTheme: [String]) {
        self.audioFileURL = audioFileURL
        self.textFileURL = textFileURL
        self.decidedTheme = decidedTheme
        // EvaluateSpeech_content のインスタンスを初期化
        _evaluateSpeechContent = StateObject(wrappedValue: EvaluateSpeech_content(conversationManager: ConversationManager(apiKey: Config.openai_apiKey)))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView { // ここを追加
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 各評価項目を縦に配置
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // WPM&Fluencyセクション
                        Text("WPM(Words Per Minute)")
                            .font(.title2) // タイトルサイズを大きく
                            .foregroundColor(.blue)
                        
                        // WPMの計算結果を表示
                        if let wpm = evaluateSpeech.evaluate_wpm(audioFileURL: audioFileURL, textFileURL: textFileURL) {
                            Text("今回のWPMは \(Int(wpm))です。")
                                .padding(.leading, 10) // フィードバック部分にインデントを追加
                                .fixedSize(horizontal: false, vertical: true)
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
                        
                        Divider() // 区切り線
                        
                        // Pronunciationセクション
                        Text("Pronunciation and Fluency")
                            .font(.title2) // タイトルサイズを大きく
                            .foregroundColor(.blue)
                        
                        if isLoading {
                            ProgressView("評価中...")
                                .padding(.leading, 10)
                        } else if let evaluationResult = evaluationResult {
                            // 各単語の評価を表示
                            if !evaluationResult.wordScoreList.isEmpty {
                                Text("評価された単語:")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                // 色付き単語を連結して表示し、適切に改行
                                buildColoredText(from: evaluationResult.wordScoreList)
                                    .padding(.leading, 10)
                                    .lineLimit(nil) // 必要に応じて改行を行う
                                    .fixedSize(horizontal: false, vertical: true) // 水平方向に収まらない場合は改行
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                // 採点結果セクション
                                Text("採点結果")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                HStack {
                                    Text("Pronunciation:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.speechacePronunciation))点")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                
                                HStack {
                                    Text("Fluency:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.speechaceFluency))点")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                
                                // IELTS換算セクション
                                Text("IELTS換算")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                HStack {
                                    Text("Pronunciation:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.ieltsPronunciation))点")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                
                                HStack {
                                    Text("Fluency:")
                                        .padding(.leading, 20)
                                    Text("\(Int(evaluationResult.ieltsFluency))点")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                
                                // CEFR換算セクション
                                Text("CEFR換算")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                HStack {
                                    Text("Pronunciation:")
                                        .padding(.leading, 20)
                                    Text("\(evaluationResult.cefrPronunciation)")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                
                                HStack {
                                    Text("Fluency:")
                                        .padding(.leading, 20)
                                    Text("\(evaluationResult.cefrFluency)")
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            
                        } else if let errorMessage = errorMessage {
                            Text("エラー: \(errorMessage)")
                                .padding(.leading, 10)
                        } else {
                            Text("評価を行うには音声ファイルとテキストファイルを提供してください。")
                                .padding(.leading, 10)
                        }
                        
                        Divider()
                        
                        // Contentセクション
                        Text("Content")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        if isThemeChecking {
                            ProgressView("テーマをチェック中...")
                                .padding(.leading, 10)
                        } else if let themeCheckResult = themeCheckResult {
                            Text("ChatGPTの応答: \(themeCheckResult)")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let themeCheckError = themeCheckError {
                            Text("エラー: \(themeCheckError)")
                                .padding(.leading, 10)
                        } else {
                            Text("評価データがありません。")
                                .padding(.leading, 10)
                        }
                        
                    }
                    .padding()
                    .onAppear {
                        fetchPronunciationEvaluation()
                        checkThemeWithChatGPT() // テーマと内容のチェックを行う
                        
                    }
                    
                }
                .padding()
            } // ScrollViewの終わり
            .navigationTitle("Report")
        }
    }
    
    private func checkThemeWithChatGPT() {
        guard let textFileURL = textFileURL else {
            themeCheckError = "テキストファイルがありません。"
            return
        }
        
        isThemeChecking = true
        
        // EvaluateSpeech_contentのテーマチェックメソッドを使用
        evaluateSpeechContent.checkTextAgainstTheme(textFileURL: textFileURL, decidedTheme: decidedTheme) { result in
            DispatchQueue.main.async {
                isThemeChecking = false
                if let result = result {
                    self.themeCheckResult = result
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
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // 各単語の評価に応じた色を返す
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
    
    // 色付きの文章を改行を含めて表示
    private func buildColoredText(from wordScoreList: [WordScore]) -> Text {
        var coloredText = Text("")
        
        for wordScore in wordScoreList {
            let wordWithColor = Text(wordScore.word + " ") // 単語の後にスペースを追加
                .foregroundColor(color(for: Double(wordScore.qualityScore))) // Doubleにキャスト
            
            coloredText = coloredText + wordWithColor
        }
        
        return coloredText // Text型のまま返す
    }
}

#Preview {
    EvaluateView(audioFileURL: nil, textFileURL: nil, decidedTheme: ["Technology", "Education"])
}
