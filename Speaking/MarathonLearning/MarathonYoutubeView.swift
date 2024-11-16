import SwiftUI
import Foundation
import SwiftSoup

struct MarathonYoutubeView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    @Binding var searchQuery: String
    @Binding var searchResults: [YoutubeVideo]
    @Binding var selectedVideo: YoutubeVideo?
    let youtubeSearchService: YoutubeSearchService
    @Binding var captionText: String
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    let repetitions: Int
    @Binding var isNavigationActive: Bool
    
    @State private var showGeneratedThemes = false
    @State private var generatedThemes: [String] = []
    
    var body: some View {
        ZStack {
            
            Image("back") // 画像名に応じて変更
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
                
                // スクロールビュー内に動画リスト、詳細表示、MicSubmitViewを含む
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
                        
                        // 選択した動画の詳細表示
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
                                    .onAppear {
                                        themeManager.DecidedTheme = [selectedVideo.title]
                                    }
                            }
                            .padding()
                            .background(Image("pokepoke2"))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        
                        
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
                                        if themeManager.DecidedTheme.contains(theme) {
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
                                    .background(themeManager.DecidedTheme.contains(theme) ? Color.mint.opacity(0.25) : Color.purple.opacity(0.08))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 選択されたテーマの表示
                    if themeManager.DecidedTheme.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("  選択されたテーマ:")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.7))
                            
                            ForEach(themeManager.DecidedTheme, id: \.self) { theme in
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
                                        
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(2)
                        }
                        // 次に進むボタン
                        Button("次に進む") {
                            isNavigationActive = true
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(themeManager.DecidedTheme.isEmpty ? Color.gray : Color.blue) // Disable if no theme is selected
                        .cornerRadius(10)
                        .disabled(themeManager.DecidedTheme.isEmpty) // Disable button if DecidedTheme is empty
                        
                        NavigationLink(destination: MarathonRecordView(tabManager: tabManager, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager)
                            .navigationBarBackButtonHidden(true), isActive: $isNavigationActive) {
                                EmptyView()
                            }
                        
                            .padding()
                    }
                }
            }
        }
    }
    
    func generateTopics() {
        themeManager.DecidedTheme = []
        
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
        if themeManager.DecidedTheme.contains(theme) {
            themeManager.DecidedTheme.removeAll { $0 == theme }
        } else {
            themeManager.DecidedTheme.append(theme)
        }
    }
}


