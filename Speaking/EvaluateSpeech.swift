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
                    print("単語数: \(Double(wordCount))")
                    print("秒数:, \(audioDuration)")
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
        // エンドポイントとAPIキーの設定
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

