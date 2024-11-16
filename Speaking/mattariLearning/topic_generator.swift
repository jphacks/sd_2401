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
    [指示]
    ・次に示すキーワードはユーザーが興味に基づいて入力した単語です。これをミックスしてスピーチテーマを5つ作成してください。
    ・スピーチテーマは短くしてください
    ・スピーチテーマは簡単にしてください（中学生レベル）
    
    [キーワード]
    \(content)
    
    出力は以下の出力形式を必ず守ってください。{}の部分はあなたが考える部分です。
    
    [出力形式]
    {
        1: "{テーマ1}",
        2: "{テーマ2}",
        ...
        5: "{テーマ5}"
    }
    
    """
        
        let message = TopicGeneratorMessage(role: "user", content: prompt)
        let request = TopicGeneratorRequest(model: "gpt-4o", messages: [message])
        
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
        
        // ChatGPTの応答を出力
        print("ChatGPT Response: \(responseContent)")
        
        // 正規表現を使用してレスポンスを有効なJSON形式に変換
        let pattern = #"(\d+):"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: responseContent.utf16.count)
        let validJSONString = regex.stringByReplacingMatches(in: responseContent, options: [], range: range, withTemplate: "\"$1\":")
        // print(validJSONString)
        
        guard let jsonData = validJSONString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            throw NSError(domain: "Invalid JSON format", code: -1)
        }
        
        // JSONデータを保存する処理
        let topics = Array(json.values)
        
        return topics
    }
    
    static func generateTopicsFromNews(content: String) async throws -> [String] {
        let prompt = """
    [指示]
    ・次に示す「ニュース記事」はユーザーが選択したニュースの内容です。重要なキーワードに着目してスピーチのテーマを5つ作成してください
    ・スピーチテーマは短くしてください
    ・スピーチテーマは簡単にしてください（高校生レベル）
    ・ユニークで面白いテーマだと良いです
    
    [ニュース記事]
    \(content)
    
    出力は以下の出力形式を必ず守ってください。{}の部分はあなたが考える部分です。
    
    [出力形式]
    {
        1: "{テーマ1}",
        2: "{テーマ2}",
        ...
        5: "{テーマ5}"
    }
    
    """
        
        let message = TopicGeneratorMessage(role: "user", content: prompt)
        let request = TopicGeneratorRequest(model: "gpt-4o", messages: [message])
        
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
        
        // ChatGPTの応答を出力
        print("ChatGPT Response: \(responseContent)")
        
        // 正規表現を使用してレスポンスを有効なJSON形式に変換
        let pattern = #"(\d+):"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: responseContent.utf16.count)
        let validJSONString = regex.stringByReplacingMatches(in: responseContent, options: [], range: range, withTemplate: "\"$1\":")
        // print(validJSONString)
        
        guard let jsonData = validJSONString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            throw NSError(domain: "Invalid JSON format", code: -1)
        }
        
        // JSONデータを保存する処理
        let topics = Array(json.values)
        
        return topics
    }

    
    static func generateTopicsFromYoutubeCaption(content: String) async throws -> [String] {
        
        let prompt = """
        [指示]
        ・以下の「タイトル」と「概要」から重要なキーワードに着目してスピーチテーマを5つ作成してください。
        ・スピーチテーマは短くしてください
        ・スピーチテーマは簡単にしてください（中学生レベル）
        ・ユニークで面白いテーマだと良いです
        
        \(content)
        
        出力は以下の出力形式を必ず守ってください。{}の部分はあなたが考える部分です。
        
        [出力形式]
        {
            1: "{テーマ1}",
            2: "{テーマ2}",
            3: "{テーマ3}",
            4: "{テーマ4}",
            5: "{テーマ5}"
        }
        
        テーマは日本語で出力してください。
        """
        
        let message = TopicGeneratorMessage(role: "user", content: prompt)
        let request = TopicGeneratorRequest(model: "gpt-4o", messages: [message])
        
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


func topic_generator(content: String, isYoutubeCaption: Bool = false, isNews: Bool = false, completion: @escaping ([String]?) -> Void) {
    Task {
        do {
            let topics: [String]
            if isYoutubeCaption {
                topics = try await TopicGenerator.generateTopicsFromYoutubeCaption(content: content)
            } else if isNews{
                topics = try await TopicGenerator.generateTopicsFromNews(content: content)
            }
            else {
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



