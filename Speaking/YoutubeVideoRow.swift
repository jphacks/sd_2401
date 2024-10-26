import SwiftUI
import SDWebImageSwiftUI

struct YoutubeVideoRow: View {
    let video: YoutubeVideo
    @Binding var isSelected: Bool
    @State private var showWebView = false
    
    var body: some View {
        Button(action: {
            if isSelected {
                // 2回目以降の押下で動画を再生
                showWebView.toggle()
            } else {
                // 初回の押下で選択状態にする
                isSelected.toggle()
            }
        }) {
            HStack {
                WebImage(url: URL(string: video.thumbnailUrl))
                    .resizable()
                    .frame(width: 100, height: 56)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                    Text(video.channelTitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .sheet(isPresented: $showWebView) {
            SafariView(url: URL(string: "https://www.youtube.com/watch?v=\(video.videoId)")!)
        }
    }
}

