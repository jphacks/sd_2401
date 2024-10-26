import Foundation

struct TopicGeneratorMessage: Codable {
    let role: String
    let content: String
}

struct TopicGeneratorRequest: Codable {
    let model: String
    let messages: [TopicGeneratorMessage]
}

struct TopicGeneratorResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

class TopicGenerator {
    static let apiKey = Config.openai_apiKey
    
    static func generateTopics(content: String) async throws -> [String] {
        let prompt = """
        [Description]
        \(content)
        
        [output format]
        {
            1: "<topic>",
            2: "<topic>",
            ...
            n: "<topic>"
        }
        
        Please create 5 presentation topics following the [Description] above.
        The output should be in json format.
        
        [output (lang='jp')]
        """
        
        let message = TopicGeneratorMessage(role: "user", content: prompt)
        let request = TopicGeneratorRequest(model: "gpt-3.5-turbo", messages: [message])
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "URL error", code: -1)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTP Error \(httpResponse.statusCode)", code: httpResponse.statusCode)
        }
        
        let decodedResponse = try JSONDecoder().decode(TopicGeneratorResponse.self, from: data)
        
        guard let responseContent = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "No content in response", code: -1)
        }
        
        // 正規表現を使用してレスポンスを有効なJSON形式に変換
        let pattern = #"(\d+):"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: responseContent.utf16.count)
        let validJSONString = regex.stringByReplacingMatches(in: responseContent, options: [], range: range, withTemplate: "\"$1\":")
        
        guard let jsonData = validJSONString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            throw NSError(domain: "Invalid JSON format", code: -1)
        }
        
        return Array(json.values)
    }
    
    static func generateTopicsFromYoutubeCaption(caption: String) async throws -> [String] {
        
        let prompt = """
        [Description]
        以下はYouTube動画の字幕です：
        \(caption)
        
        [指示]
        この字幕の内容に基づいて、5つのプレゼンテーションテーマを生成してください。
        テーマは簡潔で、字幕の主要な内容や概念を反映させてください。
        
        [output format]
        {
            1: "<topic>",
            2: "<topic>",
            3: "<topic>",
            4: "<topic>",
            5: "<topic>"
        }
        
        テーマは日本語で出力してください。
        """
        
        let message = TopicGeneratorMessage(role: "user", content: prompt)
        let request = TopicGeneratorRequest(model: "gpt-3.5-turbo", messages: [message])
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "URL error", code: -1)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTP Error \(httpResponse.statusCode)", code: httpResponse.statusCode)
        }
        
        let decodedResponse = try JSONDecoder().decode(TopicGeneratorResponse.self, from: data)
        
        guard let responseContent = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "No content in response", code: -1)
        }
        
        // 正規表現を使用してレスポンスを有効なJSON形式に変換
        let pattern = #"(\d+):"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: responseContent.utf16.count)
        let validJSONString = regex.stringByReplacingMatches(in: responseContent, options: [], range: range, withTemplate: "\"$1\":")
        
        guard let jsonData = validJSONString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            throw NSError(domain: "Invalid JSON format", code: -1)
        }
        
        return Array(json.values)
    }
}


func topic_generator(content: String, isYoutubeCaption: Bool = false, completion: @escaping ([String]?) -> Void) {
    Task {
        do {
            let topics: [String]
            if isYoutubeCaption {
                topics = try await TopicGenerator.generateTopicsFromYoutubeCaption(caption: content)
            } else {
                topics = try await TopicGenerator.generateTopics(content: content)
            }
            DispatchQueue.main.async {
                completion(topics)
            }
        } catch {
            print("トピック生成に失敗しました: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}


