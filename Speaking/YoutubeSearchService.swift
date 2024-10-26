import Foundation

class YoutubeSearchService {
    let apiKey = Config.youtube_apikey
    
    func searchYoutubeVideos(query: String, completion: @escaping ([YoutubeVideo]) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=\(encodedQuery)&key=\(apiKey)"
        
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
    
    func getCaptions(for videoId: String, completion: @escaping (String?) -> Void) {
        let urlString = "https://www.googleapis.com/youtube/v3/captions?part=snippet&videoId=\(videoId)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching captions: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let snippet = firstItem["snippet"] as? [String: Any],
                   let captionId = firstItem["id"] as? String {
                    self.downloadCaption(captionId: captionId, completion: completion)
                } else {
                    print("Failed to parse captions data")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        task.resume()
    }
    
    private func downloadCaption(captionId: String, completion: @escaping (String?) -> Void) {
        let urlString = "https://www.googleapis.com/youtube/v3/captions/\(captionId)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error downloading caption: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("No caption data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let captionText = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                completion(captionText)
            }
        }
        task.resume()
    }
}
