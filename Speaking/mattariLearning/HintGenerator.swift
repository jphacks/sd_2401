import Foundation

// MARK: - HintGeneratorMessage Struct
struct HintGeneratorMessage: Codable {
    let role: String
    let content: String
}

// MARK: - HintGeneratorRequest Struct
struct HintGeneratorRequest: Codable {
    let model: String
    let messages: [HintGeneratorMessage]
}

// MARK: - HintGeneratorResponse Struct
struct HintGeneratorResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - HintGenerator Class
class HintGenerator {
    static let apiKey = Config.openai_apiKey // OpenAIのAPIキーをConfigから取得
    
    /// 選択されたテーマとニュース記事に基づいて英語のスピーチヒントを生成します。
    /// - Parameters:
    ///   - theme: スピーチのテーマ
    ///   - article: 選択されたニュース記事
    /// - Returns: 生成された英語のスピーチヒント
    static func generateHint(theme: String, article: NewsArticle) async throws -> String? {
        guard let content = article.content else {
            return "I'm sorry, but there isn't enough content in the article to generate a hint."
        }
        
        // OpenAI Chat API用のプロンプトを準備
        let prompt = """

        \(content.prefix(500))...
        
        日本人が中学校や高校で習う英単語や英語の表現を用いて、テーマ"\(theme)"の内容を話すのに役立つ文章を出力してください。
            また、その英語の文章は以下の5つの観点を満たすようにしてください。
        
            1. 一貫性
            2. 構成
            3. 独自性
            4. 文法
            5. 語彙
        
            Use around 70 words and make sure the hint is concise and beginner-friendly.
        
            Provide the output as a straightforward English sentence enclosed in "".
        """
        
        // OpenAI Chat APIエンドポイント
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "URL error", code: -1, userInfo: nil)
        }
        
        // リクエストの準備
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディの準備
        let parameters: [String: Any] = [
            "model": "gpt-4", // または "gpt-4-turbo" を使用
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        // リクエストボディをJSONにシリアライズ
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        
        // APIリクエストの送信
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // レスポンスの確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "OpenAI API request failed with status code: \(statusCode)", code: statusCode, userInfo: nil)
        }
        
        // レスポンスデータのデコード
        let decodedResponse = try JSONDecoder().decode(HintGeneratorResponse.self, from: data)
        
        // 生成されたヒントを抽出
        guard let responseContent = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "No content in response", code: -1, userInfo: nil)
        }
        
        return responseContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// YouTubeの字幕からヒントを生成します。
    /// - Parameter caption: YouTube動画の字幕
    /// - Returns: 生成されたヒントの配列
    static func generateHintsFromYoutubeCaption(caption: String) async throws -> [String] {
        let prompt = """
        [Description]
        以下はYouTube動画の字幕です：
        \(caption)
        
        [指示]
        この字幕の内容に基づいて、5つの英語のスピーチヒントを生成してください。
        ヒントは簡潔で、字幕の主要な内容や概念を反映させてください。
        
        [output format]
        {
            1: "<hint>",
            2: "<hint>",
            3: "<hint>",
            4: "<hint>",
            5: "<hint>"
        }
        
        ヒントは英語で出力してください。
        """
        
        let message = HintGeneratorMessage(role: "user", content: prompt)
        let request = HintGeneratorRequest(model: "gpt-4", messages: [message])
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "URL error", code: -1, userInfo: nil)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "OpenAI API request failed with status code: \(statusCode)", code: statusCode, userInfo: nil)
        }
        
        let decodedResponse = try JSONDecoder().decode(HintGeneratorResponse.self, from: data)
        
        guard let responseContent = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "No content in response", code: -1, userInfo: nil)
        }
        
        // 正規表現を使用してレスポンスを有効なJSON形式に変換
        let pattern = #"(\d+):"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: responseContent.utf16.count)
        let validJSONString = regex.stringByReplacingMatches(in: responseContent, options: [], range: range, withTemplate: "\"$1\":")
        
        guard let jsonData = validJSONString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            throw NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)
        }
        
        return Array(json.values)
    }
    
    static func generateHintFromThemeOnly(theme: String) async throws -> String? {
        // OpenAI Chat API用のプロンプトを準備
        let prompt = """
            日本人が中学校や高校で習う英単語や英語の表現を用いて、テーマ"\(theme)"の内容を話すのに役立つ文章を出力してください。
            また、その英語の文章は以下の5つの観点を満たすようにしてください。

            1. 一貫性
            2. 構成
            3. 独自性
            4. 文法
            5. 語彙

            Use around 70 words and make sure the hint is concise and beginner-friendly.

            Provide the output as a straightforward English sentence enclosed in "".
            """
        
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "URL error", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAI API request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)", code: -1, userInfo: nil)
        }
        
        let decodedResponse = try JSONDecoder().decode(HintGeneratorResponse.self, from: data)
        
        guard let responseContent = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "No content in response", code: -1, userInfo: nil)
        }
        
        return responseContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

