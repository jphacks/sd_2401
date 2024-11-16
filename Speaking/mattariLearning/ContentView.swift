import SwiftUI
import Foundation
import SwiftSoup

struct ContentView: View {
    @State private var selectedMode: GameMode?
    
    enum GameMode {
        case relaxedLearning
        case marathonLearning
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Spacer()
                Spacer()
                
                Text("Enjoy English!!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                HStack(spacing: 20) {
                    Button(action: {
                        selectedMode = .relaxedLearning
                    }) {
                        Text("まったり学ぶ")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Image("gold"))
                            .foregroundColor(Color("icon_color"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        selectedMode = .marathonLearning
                    }) {
                        Text("マラソンラーニング")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Image("blue"))
                            .foregroundColor(Color("icon_color"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                
                Spacer()
                
                // Navigation Links (Invisible)
                NavigationLink(
                    destination: MattariPlayerView(),
                    tag: GameMode.relaxedLearning,
                    selection: $selectedMode,
                    label: { EmptyView() }
                )
                
                NavigationLink(
                    destination: MarathonSetupView(),
                    tag: GameMode.marathonLearning,
                    selection: $selectedMode,
                    label: { EmptyView() }
                )
            }
            .background(
                Image("homeback")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct MattariPlayerView: View {
    @State private var DecidedTheme: [String] = []
    @State private var searchQuery: String = ""
    @State private var searchResults: [YoutubeVideo] = []  // Consolidated variable for search results
    @State private var captionText: String = ""
    @State private var selectedVideo: YoutubeVideo?
    let youtubeSearchService = YoutubeSearchService()
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedTabIndex: Int = 0  // New state variable to track selected tab
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTabIndex) {
                // テーマタブ
                FavoriteThemesView()
                    .tabItem {
                        if selectedTabIndex == 0 {
                            Image("on_favorite_icon")  // Change to selected image
                        } else {
                            Image("favorite_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        Text("Favorite")
                    }
                    .tag(0)
                
                // Youtubeタブ
                YoutubeView(searchQuery: $searchQuery, searchResults: $searchResults, selectedVideo: $selectedVideo, youtubeSearchService: youtubeSearchService, captionText: $captionText, DecidedTheme: $DecidedTheme)
                    .tabItem {
                        if selectedTabIndex == 1 {
                            Image("on_youtube_icon")  // Change to selected image
                        } else {
                            Image("youtube_icon")
                                .resizable()
                                .frame(width: 4, height: 4)
                        }
                        Text("Youtube")
                    }
                    .tag(1)
                
                // ニュースタブ
                NewsView()
                    .tabItem {
                        if selectedTabIndex == 2 {
                            Image("on_news_icon")  // Change to selected image
                        } else {
                            Image("news_icon")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text("News")
                    }
                    .tag(2)
                
                // 画像テーマタブ
                ImageThemeGenerationView()
                    .tabItem {
                        if selectedTabIndex == 3 {
                            Image("on_camera_icon")  // Change to selected image
                        } else {
                            Image("camera_icon")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text("Photo")
                    }
                    .tag(3)
            }
        }
        .background(
            Image("tab_image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .shadow(radius: 8)
        )
        .padding(.bottom, keyboardHeight)
    }
}
