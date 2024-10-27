import Foundation

import Foundation

class YoutubeSearchService {
    let apiKey = Config.youtube_apikey
    
    func searchYoutubeVideos(query: String, videoDuration: String? = nil, relevanceLanguage: String? = nil, completion: @escaping ([YoutubeVideo]) -> Void) {
        // URLエンコードされたクエリ
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // ベースのURL文字列
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=\(encodedQuery)&key=\(apiKey)"
        
        // オプションのパラメータを追加
        if let videoDuration = videoDuration {
            urlString += "&videoDuration=\(videoDuration)"
        }
        if let relevanceLanguage = relevanceLanguage {
            urlString += "&relevanceLanguage=\(relevanceLanguage)"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(YoutubeSearchResponse.self, from: data)
                let videos = decodedResponse.items.map { item in
                    YoutubeVideo(
                        videoId: item.id.videoId,
                        title: item.snippet.title,
                        channelTitle: item.snippet.channelTitle,
                        thumbnailUrl: item.snippet.thumbnails.high.url
                    )
                }
                DispatchQueue.main.async {
                    completion(videos)
                }
            } catch {
                print("JSON decoding error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
        task.resume()
    }
}
