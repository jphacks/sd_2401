import Foundation
import UIKit

class ImageManager {
    
    static let shared = ImageManager()
    
    func encodeImageToBase64(image: UIImage, compressionQuality: CGFloat = 0.5) -> String? {
        // 解像度を縮小するためにリサイズ
        let targetSize = CGSize(width: 800, height: 800)
        UIGraphicsBeginImageContext(targetSize)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // JPEG形式でエンコード
        guard let imageData = resizedImage?.jpegData(compressionQuality: compressionQuality) else { return nil }
        return imageData.base64EncodedString()
    }
    
    // 画像とプロンプトを送信してレスポンスを取得
    func requestImageAnalysis(image: UIImage, prompt: String, completion: @escaping ([String]?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openai_apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 画像をBase64エンコード
        guard let base64Image = encodeImageToBase64(image: image) else {
            print("画像のエンコードに失敗しました")
            completion(nil)
            return
        }
        
        // リクエストボディを作成
        let body: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt + "\n5つの関連するスピーチテーマを日本語でリスト形式で生成してください。"
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 4096
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("JSONボディの作成エラー: \(error)")
            completion(nil)
            return
        }
        
        // リクエスト送信
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("リクエスト送信エラー: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("データが受信できませんでした")
                completion(nil)
                return
            }
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("生レスポンス: \(rawResponse)")
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let responseContent = message["content"] as? String {
                    let themes = responseContent.components(separatedBy: "\n").filter { !$0.isEmpty }.prefix(5)
                    completion(Array(themes))
                } else {
                    completion(nil)
                }
            } catch {
                print("レスポンスの解析エラー: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}

