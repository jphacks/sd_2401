import Foundation

// メッセージの構造体
struct Message: Codable {
    let role: String
    let content: String
}

// リクエストの構造体
struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let max_tokens: Int
}

// レスポンスの構造体
struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// 会話を管理するクラス
class ConversationManager {
    private let apiKey: String
    private let apiUrl: URL = URL(string: "https://api.openai.com/v1/chat/completions")! // OpenAI API URL
    private var conversationHistory: [Message] = [] // 会話履歴
    
    init(apiKey: String) {
        self.apiKey = apiKey // OpenAI APIキー
    }
    
    // 会話をするメソッド
    func Conversation(prompt: String, completion: @escaping (String?) -> Void) {
        // ユーザーのメッセージを会話履歴に追加
        let userMessage = Message(role: "user", content: prompt)
        conversationHistory.append(userMessage)
        
        // リクエストデータの作成
        let chatRequest = ChatRequest(model: "gpt-4o", messages: conversationHistory, max_tokens: 500)
        
        // リクエストを送信するメソッドを呼び出し
        sendRequest(chatRequest: chatRequest) { response in
            if let responseMessage = response {
                // レスポンスメッセージを会話履歴に追加
                let assistantMessage = Message(role: "assistant", content: responseMessage)
                self.conversationHistory.append(assistantMessage)
            }
            completion(response)
        }
    }
    
    // APIリクエストを送信するメソッド
    private func sendRequest(chatRequest: ChatRequest, completion: @escaping (String?) -> Void) {
        guard let httpBody = try? JSONEncoder().encode(chatRequest) else {
            print("Failed to encode the request.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Request error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let chatResponse = try? JSONDecoder().decode(ChatResponse.self, from: data) {
                let reply = chatResponse.choices.first?.message.content
                completion(reply)
            } else {
                print("Failed to decode response.")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // 会話履歴を消去するメソッド
    func cleanConversationHistory() {
        conversationHistory = []
    }
    
    // 会話履歴を取得するメソッド
    func getConversationHistory() -> [Message] {
        return conversationHistory
    }
}
