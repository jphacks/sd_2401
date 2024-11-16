import SwiftUI
import Foundation
import SwiftSoup

struct YoutubeView: View {
    @Binding var searchQuery: String
    @Binding var searchResults: [YoutubeVideo]
    @Binding var selectedVideo: YoutubeVideo?
    let youtubeSearchService: YoutubeSearchService
    @Binding var captionText: String
    @Binding var DecidedTheme: [String]
    @State private var generatedThemes: [String] = []
    @State private var showGeneratedThemes = false
    @State private var themeHints: [String: String] = [:]
    
    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                // 検索バー
                HStack {
                    TextField("Youtubeを検索", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        youtubeSearchService.searchYoutubeVideos(query: searchQuery) { results in
                            self.searchResults = results
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.icon)
                            .padding(10)
                            .background(Image("pokepoke"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                    }
                }
                .padding()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if searchResults.isEmpty {
                            Text("検索結果がありません")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black.opacity(0.5))
                        } else {
                            ForEach(searchResults) { video in
                                YoutubeVideoRow(video: video, isSelected: Binding(
                                    get: { self.selectedVideo?.videoId == video.videoId },
                                    set: { newValue in
                                        if newValue {
                                            self.selectedVideo = video
                                        } else {
                                            self.selectedVideo = nil
                                        }
                                    }
                                ))
                            }
                        }
                        
                        if let selectedVideo = selectedVideo {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("選択したYoutube動画:")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.black.opacity(0.7))
                                
                                Text(selectedVideo.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding()
                            .background(Image("pokepoke2"))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        
                        // テーマ生成ボタン
                        Button(action: {
                            generateTopics()
                        }) {
                            Text("テーマ生成")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Image("pokepoke2"))
                                .foregroundColor(.black.opacity(0.5))
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding()
                        
                        if showGeneratedThemes {
                            VStack(alignment: .leading) {
                                Text("生成されたテーマ:")
                                    .font(.headline)
                                
                                ForEach(generatedThemes, id: \.self) { theme in
                                    Button(action: {
                                        toggleTheme(theme)
                                    }) {
                                        HStack {
                                            if DecidedTheme.contains(theme) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                            Text(theme)
                                                .padding(.vertical, 5)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(.black.opacity(0.5))
                                                .cornerRadius(8)
                                            
                                        }
                                        .padding(.horizontal, 10)
                                        .background(DecidedTheme.contains(theme) ? Color.mint.opacity(0.25) : Color.purple.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // 選択されたテーマの表示
                        if !DecidedTheme.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("  選択されたテーマ:")
                                    .font(.headline)
                                    .foregroundColor(.black.opacity(0.7))
                                
                                ForEach(DecidedTheme, id: \.self) { theme in
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(theme)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(.black.opacity(0.5))
                                                .background(Color.mint.opacity(0.25))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                                                )
                                                .onTapGesture {
                                                    toggleTheme(theme)
                                                }
                                            
                                            // ヒント生成ボタン
                                            Button(action: {
                                                if themeHints[theme] != nil {
                                                    // ヒントが存在する場合は削除
                                                    themeHints.removeValue(forKey: theme)
                                                } else {
                                                    // ヒントが存在しない場合は生成
                                                    Task {
                                                        if let hint = try await HintGenerator.generateHintFromThemeOnly(theme: theme) {
                                                            DispatchQueue.main.async {
                                                                themeHints[theme] = hint
                                                            }
                                                        }
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "lightbulb")
                                                    .foregroundColor(.yellow)
                                            }
                                            .padding(.leading, 10)
                                        }
                                        
                                        if let hint = themeHints[theme] {
                                            Text("ヒント: \(hint)")
                                                .padding()
                                                .foregroundColor(.gray)
                                                .background(Color.white.opacity(0.7))
                                                .cornerRadius(10)
                                                .transition(.opacity)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(2)
                        }
                        
                        MicSubmitView(decidedTheme: Binding(
                            get: { selectedVideo?.title != nil ? [selectedVideo!.title] : [] },
                            set: { newValue in
                                if let firstValue = newValue.first {
                                    self.selectedVideo = YoutubeVideo(videoId: firstValue, title: firstValue, channelTitle: "チャンネル名", thumbnailUrl: "サムネイルURL", description: firstValue)
                                } else {
                                    self.selectedVideo = nil
                                }
                            }
                        ))
                    }
                    .padding()
                }
            }
        }
    }
    
    func generateTopics() {
        DecidedTheme = []
        
        guard let selectedVideo = selectedVideo else {
            print("動画が選択されていません")
            return
        }
        
        let title = selectedVideo.title
        let description = selectedVideo.description
        let content = """
            タイトル：\(title)
            概要：\(description)
            """
        
        topic_generator(content: content, isYoutubeCaption: true) { topics in
            if let generated = topics {
                DispatchQueue.main.async {
                    self.generatedThemes = generated
                    self.showGeneratedThemes = true
                }
            } else {
                print("トピック生成に失敗しました")
            }
        }
    }
    
    func toggleTheme(_ theme: String) {
        if DecidedTheme.contains(theme) {
            DecidedTheme.removeAll { $0 == theme }
            themeHints.removeValue(forKey: theme)
        } else {
            DecidedTheme.append(theme)
        }
    }
}

