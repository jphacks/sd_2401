import Foundation
import AVFoundation

// 評価クラス

class EvaluateSpeech: ObservableObject {
    
    // 音声ファイルや音声認識後のテキストファイルの有効性を評価
    func evaluate_valid(audioFileURL: URL?, textFileURL: URL?, minAudioDuration: Double) -> Bool {
        var isAudioValid = false
        var isTextValid = false
        
        // 音声ファイルの存在確認
        if let audioFileURL = audioFileURL {
            if FileManager.default.fileExists(atPath: audioFileURL.path) {
                print("Audio file exists at: \(audioFileURL)")
                // 音声ファイルの評価ロジック
                do {
                    let audioFile = try AVAudioFile(forReading: audioFileURL)
                    let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate // Int64をDoubleに変換
                    // 指定した時間以上かどうかをチェック
                    if duration >= minAudioDuration {
                        isAudioValid = true
                    }
                } catch {
                    print("Error reading audio file: \(error)")
                }
            } else {
                print("Audio file does not exist.")
            }
        } else {
            print("No audio file URL provided.")
        }
        
        // テキストファイルの存在確認
        if let textFileURL = textFileURL {
            if FileManager.default.fileExists(atPath: textFileURL.path) {
                do {
                    let savedText = try String(contentsOf: textFileURL, encoding: .utf8)
                    print("Text file contents:\n\(savedText)")
                    // テキストファイルが空でないかチェック
                    if !savedText.isEmpty {
                        isTextValid = true
                    }
                } catch {
                    print("Error reading text file: \(error)")
                }
            } else {
                print("Text file does not exist.")
            }
        } else {
            print("No text file URL provided.")
        }
        
        // 条件を満たしているかを返す
        return isAudioValid && isTextValid
    }
    
    // wpmを計算する
    func evaluate_wpm(audioFileURL: URL?, textFileURL: URL?) -> Double? {
        var wpm: Double = 0.0
        var audioDuration: Double = 0.0
        
        // 音声ファイルの再生時間を取得
        if let audioFileURL = audioFileURL {
            if FileManager.default.fileExists(atPath: audioFileURL.path) {
                do {
                    let audioFile = try AVAudioFile(forReading: audioFileURL)
                    let sampleRate = audioFile.fileFormat.sampleRate
                    let lengthInFrames = Double(audioFile.length)
                    
                    // サンプルフレーム数をサンプルレートで割って秒数を計算
                    audioDuration = lengthInFrames / sampleRate
                } catch {
                    print("音声ファイルの読み込みエラー: \(error)")
                    return nil
                }
            } else {
                print("音声ファイルが存在しません")
                return nil
            }
        }
        
        // テキストファイルの単語数をカウントしてWPMを計算
        if let textFileURL = textFileURL {
            do {
                let text = try String(contentsOf: textFileURL, encoding: .utf8)
                
                // WPM（Words Per Minute）の計算
                let wordCount = text.split { $0.isWhitespace }.count
                if audioDuration > 0 {
                    wpm = Double(wordCount) / (audioDuration / 60.0) // 分あたりの単語数を計算
                }
            } catch {
                print("テキストファイルの読み込みエラー: \(error)")
                return nil
            }
        } else {
            print("テキストファイルが存在しません")
            return nil
        }
        
        // WPMを返す
        return wpm
    }
    
    func evaluatePronunciationAndProcess(
        audioFileURL: URL,
        textFileURL: URL,
        completion: @escaping (Result<ProcessedEvaluationData, Error>) -> Void
    ) {
        let apiEndpoint = Config.Speechace_apiendpoint
        
        // 音声ファイルデータの取得
        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            completion(.failure(NSError(domain: "Error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "音声ファイルのデータ取得に失敗しました"])))
            return
        }
        
        // テキストファイルのデータ取得
        guard let textData = try? String(contentsOf: textFileURL, encoding: .utf8) else {
            completion(.failure(NSError(domain: "Error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "テキストファイルのデータ取得に失敗しました"])))
            return
        }
        
        // APIに送信するためのリクエストの作成
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        
        // boundaryを使用してmultipart/form-dataを設定
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // multipartフォームデータの作成
        var body = Data()
        let text = textData  // テキストファイルの内容を使用
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(text)\r\n".data(using: .utf8)!)
        
        // 音声ファイルの追加
        let filename = audioFileURL.lastPathComponent
        let mimeType = "audio/wav"  // 適切なMIMEタイプを指定
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_audio_file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 追加パラメータ
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"include_fluency\"\r\n\r\n1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"no_mc\"\r\n\r\n1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"include_unknown_words\"\r\n\r\n1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // APIリクエストを送信
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "Error", code: 1002, userInfo: [NSLocalizedDescriptionKey: "データが取得できませんでした"])))
                return
            }
            
            // レスポンスをファイルに保存
            let fileName = "pronunciationResult.json"
            let fileManager = FileManager.default
            if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: fileURL)
                    print("JSONデータが \(fileURL) に保存されました")
                } catch {
                    completion(.failure(error))
                    return
                }
            }
            
            // JSONデータをデコード
            let decoder = JSONDecoder()
            do {
                let evaluationResponse = try decoder.decode(EvaluationResponse.self, from: data)
                
                // 必要な情報を取り出す
                let text = evaluationResponse.textscore.text
                let ieltsScore = evaluationResponse.textscore.ieltsScore
                let speechaceScore = evaluationResponse.textscore.speechaceScore
                let cefrScore = evaluationResponse.textscore.cefrScore
                let wordScoreList = evaluationResponse.textscore.wordScoreList
                
                // WordScore型の配列を作成
                var wordScoreArray: [WordScore] = []
                
                for wordScore in wordScoreList {
                    let wordScoreItem = WordScore(word: wordScore.word, qualityScore: wordScore.qualityScore)
                    wordScoreArray.append(wordScoreItem)
                }
                
                // ProcessedEvaluationData 構造体にデータをまとめて返す
                let processedData = ProcessedEvaluationData(
                    text: text,
                    ieltsPronunciation: ieltsScore.pronunciation,
                    ieltsFluency: ieltsScore.fluency,
                    speechacePronunciation: speechaceScore.pronunciation,
                    speechaceFluency: speechaceScore.fluency,
                    cefrPronunciation: cefrScore.pronunciation,
                    cefrFluency: cefrScore.fluency,
                    wordScoreList: wordScoreArray
                )
                
                completion(.success(processedData))
                
            } catch {
                print("JSONデコードエラー: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
}


class EvaluateSpeech_content: ObservableObject {
    private var conversationManager: ConversationManager
    
    // 各評価のスコアを保持する変数
    @Published var consistencyScore: Int?
    @Published var structureScore: Int?
    @Published var originalityScore: Int?
    @Published var grammarScore: Int?
    @Published var vocabularyScore: Int?
    
    // イニシャライザでconversationManagerを初期化
    init(conversationManager: ConversationManager) {
        self.conversationManager = conversationManager
    }
    
    // テーマとテキストファイルの内容を評価するメソッド
    func checkTextAgainstTheme(textFileURL: URL, decidedTheme: [String], completion: @escaping (String?) -> Void) {
        do {
            let textContent = try String(contentsOf: textFileURL, encoding: .utf8)
            let prompt = """
            スピーチのテーマ： \(decidedTheme.joined(separator: ", ")). 
            テキストファイルの内容: \(textContent).
            テキストファイルを次の観点a-eで評価し、その評価が改善されるような修正案を示してください。
            a. テキストファイルの内容がスピーチのテーマに合っているか。
            b. スピーチの構成は適切であり論理構造が明確であるか。
            c. スピーチの内容に独自性（具体例や経験）が適切に含まれているか
            d. 文法は正確に使うことができているか。
            e. 多様な語彙が使えているか。
            
            修正案は以下の仕様を全て必ず守ってください。
            ・修正案は英文で書き、一部でなく全て示すこと。
            ・もとのテキストファイルの内容を尊重し、修正が必要な部分のみを修正すること。（評価が非常に低い場合はこれに従う必要はない。）
            ・あなたの行った評価や提案内容との対応がユーザーにとって明確であるような修正案を提示すること。
            ・英文の最初と最後を""で囲うこと。
            ・修正案は難しい語彙、表現を用いないこと。
            
            出力形式は以下のようにしてください。改行、インデントも守ってください。{}の部分はあなたが考える部分です。
            良い回答にはしっかり満点をつけてください。
            
            1. 一貫性
            　　評価：{観点aの評価(10段階)/10}
            　　理由：{評価の理由を簡潔に書く。}
            2. 構成
               評価：{観点bの評価(10段階)/10}
               理由：{評価の理由を簡潔に書く。}
            3. 独自性
            　　評価：{観点cの評価(10段階)/10}
            　　理由：{評価の理由を簡潔に書く。}
            4. 文法
            　　評価：{観点dの評価(5段階)/5}
            　　理由：{評価の理由を簡潔に書く。より適切な文法表現を必ず提案する。}
            5. 語彙
            　　評価：{観点eの評価(5段階)/5}
            　　理由：{評価の理由を簡潔に書く。語彙が偏っている部分に対して新しい語彙を必ず具体的に提案する。}
            改善案　
            　　{修正された英文を書く。仕様を必ず守ること。｝
            """
            
            conversationManager.Conversation(prompt: prompt) { [weak self] response in
                guard let self = self, let response = response else {
                    completion(nil)
                    return
                }
                
                // 出力を解析し、各評価スコアを抽出
                self.parseEvaluationResponse(response)
                completion(response)
            }
        } catch {
            print("テキストファイルの読み込みに失敗しました: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // レスポンスからスコアを解析して格納するメソッド
    func parseEvaluationResponse(_ response: String) {
        DispatchQueue.main.async { [weak self] in
            // 一貫性
            if let consistencyMatch = response.range(of: #"一貫性\s*\n?\s*評価：\s*(\d+)/10"#, options: .regularExpression),
               let consistencyScore = Int(response[consistencyMatch].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().prefix(1)) {
                print("一貫性スコア: \(consistencyScore)")
                self?.consistencyScore = consistencyScore
            }
            
            // 構成
            if let structureMatch = response.range(of: #"構成\s*\n?\s*評価：\s*(\d+)/10"#, options: .regularExpression),
               let structureScore = Int(response[structureMatch].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().prefix(1)) {
                print("構成スコア: \(structureScore)")
                self?.structureScore = structureScore
            }
            
            // 独自性
            if let originalityMatch = response.range(of: #"独自性\s*\n?\s*評価：\s*(\d+)/10"#, options: .regularExpression),
               let originalityScore = Int(response[originalityMatch].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().prefix(1)) {
                print("独自性スコア: \(originalityScore)")
                self?.originalityScore = originalityScore
            }
            
            // 文法
            if let grammarMatch = response.range(of: #"文法\s*\n?\s*評価：\s*(\d+)/5"#, options: .regularExpression),
               let grammarScore = Int(response[grammarMatch].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().prefix(1)) {
                print("文法スコア: \(grammarScore)")
                self?.grammarScore = grammarScore
            }
            
            // 語彙
            if let vocabularyMatch = response.range(of: #"語彙\s*\n?\s*評価：\s*(\d+)/5"#, options: .regularExpression),
               let vocabularyScore = Int(response[vocabularyMatch].components(separatedBy: CharacterSet.decimalDigits.inverted).joined().prefix(1)) {
                print("語彙スコア: \(vocabularyScore)")
                self?.vocabularyScore = vocabularyScore
            }
        }
    }
    
    
    // 各スコアを利用して総合スコアを計算する関数
    func calculateTotalScore() -> Int? {
        guard let consistency = consistencyScore,
              let structure = structureScore,
              let originality = originalityScore,
              let grammar = grammarScore,
              let vocabulary = vocabularyScore else {
            // すべてのスコアが揃っていない場合はnilを返す
            return nil
        }
        
        // 総合スコアの計算（
        let totalScore = Double(consistency + structure + originality + grammar + vocabulary) * (5.0 / 2.0)
        return Int(totalScore)
    }
}


// JSONの構造を表すデータモデル
struct EvaluationResponse: Codable {
    let status: String
    let quotaRemaining: Int
    let textscore: TextScore
    
    enum CodingKeys: String, CodingKey {
        case status
        case quotaRemaining = "quota_remaining"
        case textscore = "text_score"
    }
}

struct TextScore: Codable {
    let text: String
    let wordScoreList: [WordScore]
    let ieltsScore: IELTSScore
    let speechaceScore: SpeechAceScore
    let cefrScore: CEFRScore
    
    enum CodingKeys: String, CodingKey {
        case text
        case wordScoreList = "word_score_list"
        case ieltsScore = "ielts_score"
        case speechaceScore = "speechace_score"
        case cefrScore = "cefr_score"
    }
}

// 各単語の評価データを表すモデル
struct WordScore: Codable {
    let word: String
    let qualityScore: Int
    
    enum CodingKeys: String, CodingKey {
        case word
        case qualityScore = "quality_score"
    }
}

struct IELTSScore: Codable {
    let pronunciation: Double
    let fluency: Double
}

struct SpeechAceScore: Codable {
    let pronunciation: Double
    let fluency: Double
}

struct CEFRScore: Codable {
    let pronunciation: String
    let fluency: String
}

struct ProcessedEvaluationData {
    let text: String
    let ieltsPronunciation: Double
    let ieltsFluency: Double
    let speechacePronunciation: Double
    let speechaceFluency: Double
    let cefrPronunciation: String
    let cefrFluency: String
    let wordScoreList: [WordScore] // ここは WordScore 型の配列
}


