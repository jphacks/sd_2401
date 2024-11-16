
import SwiftUI

struct MarathonDecideThemeView: View {
    
    @ObservedObject var tabManager: TabManager
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    @State private var newTheme = ""
    @State private var selectedTheme: String? = nil
    @State private var isMicActive = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var maxThemes = 4
    @State private var generatedThemes: [String] = []
    @State private var generatedTopics: [String] = []
    @ObservedObject var themeManager: ThemeManager
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [YoutubeVideo] = []
    @State private var selectedVideo: YoutubeVideo?
    @State private var captionText: String = ""
    let youtubeSearchService = YoutubeSearchService()
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    let repetitions: Int
    
    // Timer and navigation states
    @State private var timerCount: Int = 60
    @State private var isTimerActive: Bool = true
    @State private var isNavigationActive: Bool = false
    @State private var isExitNavigationActive: Bool = false
    
    var body: some View {
        VStack{
            TabView(selection: $tabManager.selectedTabIndex) {
                // テーマタブ
                MarathonFavoriteThemesView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, favoriteTopicsManager: favoriteTopicsManager, themeManager: themeManager, repetitions: repetitions, isNavigationActive: $isNavigationActive)
                    .tabItem {
                        if tabManager.selectedTabIndex == 0 {
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
                MarathonYoutubeView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, searchQuery: $searchQuery, searchResults: $searchResults, selectedVideo: $selectedVideo, youtubeSearchService: youtubeSearchService, captionText: $captionText, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, isNavigationActive: $isNavigationActive)
                    .tabItem {
                        if tabManager.selectedTabIndex == 1 {
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
                MarathonNewsView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, isNavigationActive: $isNavigationActive)
                    .tabItem {
                        if tabManager.selectedTabIndex == 2 {
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
                MarathonImageThemeGenerationView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, isNavigationActive: $isNavigationActive)
                    .tabItem {
                        if tabManager.selectedTabIndex == 3 {
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

    
            Text("残り時間: \(timerCount)s")
                .font(.subheadline)
                .foregroundColor(.red)
  
            
            
            NavigationLink(destination: ContentView()
                .navigationBarBackButtonHidden(true), isActive: $isExitNavigationActive) {
                    EmptyView()
                }
            
            NavigationLink(destination: MarathonRecordView(tabManager: tabManager, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager)
                .navigationBarBackButtonHidden(true), isActive: $isNavigationActive) {
                    EmptyView()
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
        .onAppear {
            startTimer()
        }
        .navigationBarItems(trailing: Button("終了") {
            isExitNavigationActive = true
        })
        
        
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timerCount > 0 && isTimerActive {
                timerCount -= 1
            } else {
                timer.invalidate()
                isNavigationActive = true
            }
        }
    }
    
    func subscribeToKeyboardEvents() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (notification) in
            if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardSize.height
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (notification) in
            self.keyboardHeight = 0
        }
    }
}

