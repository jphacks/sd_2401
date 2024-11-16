import Foundation


struct YoutubeSearchResponse: Codable {
    let items: [YoutubeSearchItem]
}

struct YoutubeSearchItem: Codable {
    let id: YoutubeVideoId
    let snippet: YoutubeSnippet
}

struct YoutubeVideoId: Codable {
    let videoId: String
}

struct YoutubeSnippet: Codable {
    let title: String
    let channelTitle: String
    let description: String // 追加
    let thumbnails: YoutubeThumbnails
}

struct YoutubeThumbnails: Codable {
    let high: YoutubeThumbnail
}

struct YoutubeThumbnail: Codable {
    let url: String
}

struct YoutubeVideo: Identifiable {
    let id = UUID()
    let videoId: String
    let title: String
    let channelTitle: String
    let thumbnailUrl: String
    let description: String // 追加
}

