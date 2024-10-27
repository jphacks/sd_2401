import Foundation

// APIキー
let apiKey = Config.NewsAPI

// ニュース記事を取得する関数（待機処理を内部に組み込む）
func fetchNews(keyword: String) -> [[String: String]]? {
    var articlesArray: [[String: String]]?
    let dispatchGroup = DispatchGroup()
    
    dispatchGroup.enter()
    
    let endpoint = "https://newsapi.org/v2/everything"
    let urlString = "\(endpoint)?q=\(keyword)&apiKey=\(Config.NewsAPI)&pageSize=5"
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        defer {
            dispatchGroup.leave()
        }
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("No data received")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let newsResponse = try decoder.decode(NewsResponse.self, from: data)
            
            articlesArray = newsResponse.articles.compactMap { article in
                guard let url = URL(string: article.url) else { return nil }
                return ["url": article.url, "title": article.title]
            }
        } catch {
            print("Decoding error: \(error.localizedDescription)")
        }
    }
    
    task.resume()
    dispatchGroup.wait()
    
    return articlesArray
}

struct NewsResponse: Codable {
    let articles: [Article]
}

struct Article: Codable {
    let title: String
    let description: String?
    let url: String
    let content: String?
}
// 実行例
// if let articles = fetchNews(keyword: "AI") {
//     for article in articles {
//         if let url = article["url"], let content = article["content"] {
//             print("URL: \(url)")
//             print("Content: \(content)")
//             print("---------")
//         }
//     }
// } else {
//     print("ニュースを取得できませんでした")
// }
