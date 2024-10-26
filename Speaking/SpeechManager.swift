import Foundation
import AVFoundation
import Speech
import Combine

class SpeechManager: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var audioFileURL: URL?
    private var audioFile: AVAudioFile?
    @Published var textFileURL: URL?
    private var accumulatedText: String = ""
    
    var useWhisperAPI: Bool = true
    
    init() {
        requestSpeechAuthorization()
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Authorized")
            case .denied:
                print("Denied")
            case .restricted, .notDetermined:
                print("Not available")
            default:
                break
            }
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            self.audioFileURL = self.getAudioFileURL()
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            self.audioFile = try AVAudioFile(forWriting: self.audioFileURL!, settings: recordingFormat.settings)
            
            self.accumulatedText = ""
            
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.saveAudioBuffer(buffer: buffer, format: recordingFormat)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        saveAudioFile()
    }
    
    private func getAudioFileURL() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("ドキュメントディレクトリが見つかりませんでした")
        }
        return documentDirectory.appendingPathComponent("recordedAudio.wav")
    }
    
    private func saveAudioBuffer(buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        guard let audioFile = audioFile else { return }
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("音声データ書き込み中にエラーが発生しました: \(error)")
        }
    }
    
    private func saveAudioFile() {
        guard let audioFile = audioFile else { return }
        audioFile.close()
        print("音声ファイルが保存されました: \(audioFileURL!)")
    }
    
    // 修正：completionクロージャを引数に追加
    func transcribeAudioFile(completion: @escaping (Bool) -> Void) {
        if useWhisperAPI {
            transcribeUsingWhisperAPI(completion: completion)
        } else {
            transcribeUsingSpeechFramework(completion: completion)
        }
    }
    
    // Whisper APIを使った音声認識
    private func transcribeUsingWhisperAPI(completion: @escaping (Bool) -> Void) {
        guard let fileURL = audioFileURL else {
            print("音声ファイルが見つかりません")
            completion(false) // 修正：completionクロージャを呼び出し
            return
        }
        
        let apiKey = Config.openai_apiKey
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let modelParameter = "whisper-1"
        let languageParameter = "en"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        data.append(try! Data(contentsOf: fileURL))
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(modelParameter)\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(languageParameter)\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let error = error {
                print("Whisper APIエラー: \(error.localizedDescription)")
                completion(false) // 修正：失敗時にcompletionを呼び出し
                return
            }
            
            if let data = responseData, let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let text = result["text"] as? String {
                    DispatchQueue.main.async {
                        self.accumulatedText = text
                        self.saveTextToFile(text: self.accumulatedText)
                        self.displaySavedText()
                        completion(true) // 成功時にcompletionを呼び出し
                    }
                } else {
                    print("Unexpected JSON structure: \(result)")
                    completion(false) // エラーハンドリング
                }
            }
        }
        task.resume()
    }
    
    // Speechフレームワークを使った音声認識
    private func transcribeUsingSpeechFramework(completion: @escaping (Bool) -> Void) {
        guard let fileURL = audioFileURL else {
            print("音声ファイルが見つかりません")
            completion(false)
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("音声認識中にエラーが発生しました: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let result = result {
                let currentText = result.bestTranscription.formattedString
                self.accumulatedText += currentText + " "
                
                if result.isFinal {
                    self.saveTextToFile(text: self.accumulatedText)
                    self.displaySavedText()
                    completion(true)
                }
            }
        }
    }
    
    private func saveTextToFile(text: String) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            print("ドキュメントディレクトリが見つかりません")
            return
        }
        
        let textFileURL = documentDirectory.appendingPathComponent("recognizedText.txt")
        
        do {
            try text.write(to: textFileURL, atomically: true, encoding: .utf8)
            print("テキストファイルが保存されました: \(textFileURL)")
            self.textFileURL = textFileURL
        } catch {
            print("テキストファイルの保存に失敗しました: \(error)")
        }
    }
    
    private func displaySavedText() {
        guard let textFileURL = textFileURL else { return }
        
        do {
            let savedText = try String(contentsOf: textFileURL, encoding: .utf8)
            print("テキストファイルの内容: \(savedText)")
        } catch {
            print("テキストファイルの読み込みに失敗しました: \(error)")
        }
    }
}


