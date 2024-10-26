import SwiftUI

struct EvaluateView: View {
    // audioFileURL と textFileURL を引数として受け取る
    let audioFileURL: URL?
    let textFileURL: URL?
    
    // EvaluateSpeech のインスタンスを持つ
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    
    // 評価結果を保持するための状態変数
    @State private var evaluationResult: ProcessedEvaluationData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView { // ScrollViewを追加
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
                            // 70点以下の単語をフィルタリング
                            let lowScoreWords = evaluationResult.wordScoreList.filter { $0.qualityScore <= 70 }
                            // 71点以上80点以下の単語をフィルタリング
                            let mediumScoreWords = evaluationResult.wordScoreList.filter { $0.qualityScore > 70 && $0.qualityScore <= 80 }
                            
                            // 70点以下の単語を表示
                            if !lowScoreWords.isEmpty {
                                Text("70点以下の単語:")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                // 6列のLazyVGridを使用
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 6), spacing: 1) {
                                    ForEach(lowScoreWords, id: \.word) { wordScore in
                                        Text(wordScore.word)
                                            .font(.footnote)
                                            .foregroundColor(color(for: Double(wordScore.qualityScore)))
                                            .padding(5)
                                            .background(Color.gray.opacity(0.1)) // 背景色を追加して視認性を向上
                                            .cornerRadius(5)
                                    }
                                }
                                .padding(.leading, 10) // パディングを追加
                            }
                            
                            // 71点以上80点以下の単語を表示
                            if !mediumScoreWords.isEmpty {
                                Text("71点以上80点以下の単語:")
                                    .font(.headline)
                                    .padding(.leading, 10)
                                
                                // 6列のLazyVGridを使用
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 6), spacing: 1) {
                                    ForEach(mediumScoreWords, id: \.word) { wordScore in
                                        Text(wordScore.word)
                                            .font(.footnote)
                                            .foregroundColor(color(for: Double(wordScore.qualityScore)))
                                            .padding(5)
                                            .background(Color.gray.opacity(0.1)) // 背景色を追加して視認性を向上
                                            .cornerRadius(5)
                                    }
                                }
                                .padding(.leading, 10) // パディングを追加
                            }
                            
                            Text("採点結果")
                                .font(.headline)
                                .padding(.leading, 10)
                            Text("Pronunciation: \(Int(evaluationResult.speechacePronunciation))点")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Fluency: \(Int(evaluationResult.speechaceFluency))点")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("IELTS換算")
                                .font(.headline)
                                .padding(.leading, 10)
                            Text("Pronunciation: \(Int(evaluationResult.ieltsPronunciation))点")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Fluency: \(Int(evaluationResult.ieltsFluency))点")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("CEFR換算")
                                .font(.headline)
                                .padding(.leading, 10)
                            Text("Pronunciation: \(evaluationResult.cefrPronunciation)")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Fluency: \(evaluationResult.cefrFluency)")
                                .padding(.leading, 10)
                                .fixedSize(horizontal: false, vertical: true)
                            
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
                            .font(.title2) // タイトルサイズを大きく
                            .foregroundColor(.blue)
                        
                        if let evaluationResult = evaluationResult {
                            Text("Pronunciation is excellent, with clear articulation and correct stress patterns. Minor improvements could be made to intonation on specific words.")
                                .padding(.leading, 10) // フィードバック部分にインデントを追加
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("評価データがありません。")
                                .padding(.leading, 10)
                        }
                    }
                    .padding()
                    .onAppear {
                        fetchPronunciationEvaluation() // ビューが表示されたときに評価を取得
                    }
                    
                    Spacer()
                    
                }
                .padding()
                .navigationTitle("Report")
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
        case 81...100:
            return .green
        case 71..<81:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    // ここで一時的に適当なURLを渡しておく
    EvaluateView(audioFileURL: nil, textFileURL: nil)
}

