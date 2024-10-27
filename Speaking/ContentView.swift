import SwiftUI
import Foundation


struct ContentView: View {
    @State private var selectedMode: GameMode?
    
    enum GameMode {
        case singlePlayer
        case twoPlayer
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Button(action: {
                    selectedMode = .singlePlayer
                }) {
                    Text("Single Player")
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    selectedMode = .twoPlayer
                }) {
                    Text("Two Player")
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(
                    destination: SinglePlayerView(),
                    tag: GameMode.singlePlayer,
                    selection: $selectedMode,
                    label: { EmptyView() }
                )
                
                NavigationLink(
                    destination: TwoPlayerView(),
                    tag: GameMode.twoPlayer,
                    selection: $selectedMode,
                    label: { EmptyView() }
                )
            }
        }
    }
}

struct SinglePlayerView: View {
    @State private var favoriteThemes = ["ゲーム", "フード", "モンハン", "アニメ"]
    @State private var newTheme = ""
    @State private var selectedMode: String? = "好きなテーマ"
    @State private var showGeneratedThemes = false
    @State private var selectedTheme: String? = nil
    @State private var isMicActive = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var maxThemes = 4
    @State private var generatedThemes: [String] = []
    @State private var generatedTopics: [String] = []
    @State private var DecidedTheme: [String] = []
    @State private var isRecording = false
    @State private var canNavigate = false
    @State private var showAlert = false
    @State private var minAudioDuration: Double = 10
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [YoutubeVideo] = []
    @State private var selectedVideo: YoutubeVideo?
    @State private var captionText: String = ""
    let youtubeSearchService = YoutubeSearchService()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    
    var body: some View {
        ScrollView {
            VStack {
                // Mode Selection
                HStack {
                    ForEach(["好きなテーマ", "Youtube", "News"], id: \.self) { mode in
                        Button(action: {
                            selectedMode = mode
                        }) {
                            Text(mode)
                                .padding()
                                .background(selectedMode == mode ? Color.green : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Display selected mode content
                if selectedMode == "好きなテーマ" {
                    FavoriteThemesView(
                        favoriteThemes: $favoriteThemes,
                        newTheme: $newTheme,
                        showGeneratedThemes: $showGeneratedThemes,
                        generatedThemes: $generatedThemes,
                        DecidedTheme: $DecidedTheme,
                        addNewTheme: addNewTheme,
                        generateTopics: generateTopics,
                        selectTheme: selectTheme
                    )
                } else if selectedMode == "Youtube" {
                    YoutubeView(searchQuery: $searchQuery, searchResults: $searchResults, selectedVideo: $selectedVideo, youtubeSearchService: youtubeSearchService, captionText: $captionText,
                        DecidedTheme: $DecidedTheme)
                } else if selectedMode == "News" {
                    NewsView()
                }
                
                Spacer()
                
                
                // Mic Button
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        canNavigate = false
                        speechManager.startRecording()
                    } else {
                        speechManager.stopRecording()
                        speechManager.transcribeAudioFile { success in
                            if success {
                                let audioURL = speechManager.audioFileURL
                                let textURL = speechManager.textFileURL
                                
                                if let audioURL = audioURL, let textURL = textURL {
                                    canNavigate = evaluateSpeech.evaluate_valid(audioFileURL: audioURL, textFileURL: textURL, minAudioDuration: minAudioDuration)
                                } else {
                                    canNavigate = false
                                }
                            } else {
                                canNavigate = false
                            }
                        }
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(isRecording ? .red : .black)
                        .font(.system(size: 40))
                }
                .padding()
                
                // Evaluate and Navigation
                if canNavigate {
                    NavigationLink(destination: EvaluateView(audioFileURL: speechManager.audioFileURL, textFileURL: speechManager.textFileURL, decidedTheme: DecidedTheme)) {
                        Text("音声の提出")
                            .padding()
                            .frame(width: UIScreen.main.bounds.width / 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        showAlert = true
                    }) {
                        Text("音声の提出")
                            .padding()
                            .frame(width: UIScreen.main.bounds.width / 2)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("エラー"), message: Text("指定した時間以上の音声が保存されていません。"), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .padding(.bottom, keyboardHeight)
            .onAppear {
                self.subscribeToKeyboardEvents()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self)
            }
        }
        .navigationTitle("モード選択")
    }
    
    func addNewTheme() {
        if !newTheme.isEmpty {
            favoriteThemes.append(newTheme)
            newTheme = ""
        }
    }
    
    func generateTopics() {
        let content: String
        if selectedMode == "好きなテーマ" {
            content = favoriteThemes.joined(separator: ", ")
        } else if selectedMode == "Youtube" {
            content = captionText
        } else {
            content = "ニュースの内容をここに追加"
        }
        
        topic_generator(content: content) { topics in
            if let generated = topics {
                self.generatedThemes = generated
                self.showGeneratedThemes = true
            } else {
                print("トピック生成に失敗しました")
            }
        }
    }
    
    func selectTheme(_ theme: String) {
        if DecidedTheme.contains(theme) {
            DecidedTheme.removeAll { $0 == theme }
        } else {
            DecidedTheme.append(theme)
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


struct YoutubeView: View {
    @Binding var searchQuery: String
    @Binding var searchResults: [YoutubeVideo]
    @Binding var selectedVideo: YoutubeVideo?
    let youtubeSearchService: YoutubeSearchService
    @Binding var captionText: String
    @Binding var DecidedTheme: [String]
    var theme = "この動画の概要を説明してください"
    
    var body: some View {
        VStack {
            TextField("検索ワードを入力", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                youtubeSearchService.searchYoutubeVideos(query: searchQuery, videoDuration: "short") { results in
                    self.searchResults = results
                }
            }) {
                Text("検索")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if searchResults.isEmpty {
                Text("検索結果がありません")
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(searchResults) { video in
                            YoutubeVideoRow(video: video, isSelected: Binding(
                                get: { self.selectedVideo?.id == video.id },
                                set: { newValue in
                                    if newValue {
                                        self.selectedVideo = video
                                        self.DecidedTheme = [video.title] // DecidedThemeを更新
                                    } else {
                                        self.selectedVideo = nil
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            
            // 選択された動画のタイトルを表示
            if let selectedVideo = selectedVideo {
                Text("選択された動画: \(selectedVideo.title)")
                    .font(.headline)
                    .padding()
                
                Text(theme)
                    .font(.headline)
                    .padding()
            }
        }
        .padding()
    }
}

struct FavoriteThemesView: View {
    @Binding var favoriteThemes: [String]
    @Binding var newTheme: String
    @Binding var showGeneratedThemes: Bool
    @Binding var generatedThemes: [String]
    @Binding var DecidedTheme: [String]
    
    var addNewTheme: () -> Void
    var generateTopics: () -> Void
    var selectTheme: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("好きなテーマ")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(favoriteThemes, id: \.self) { theme in
                    ZStack(alignment: .topLeading) {
                        Text(theme)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        
                        Button(action: {
                            removeTheme(theme: theme)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .offset(x: -5, y: -5)
                    }
                }
            }
            
            HStack {
                TextField("新しいテーマ", text: $newTheme)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addNewTheme) {
                    Text("追加")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Theme Generation Button
            Button(action: generateTopics) {
                Text("テーマ生成")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            // Display Generated Themes
            if showGeneratedThemes {
                VStack(alignment: .leading) {
                    ForEach(generatedThemes, id: \.self) { theme in
                        Button(action: {
                            selectTheme(theme)
                        }) {
                            Text(theme)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DecidedTheme.contains(theme) ? Color.green : Color.gray.opacity(0.2))
                                .foregroundColor(DecidedTheme.contains(theme) ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            
            // Display Selected Themes
            if !DecidedTheme.isEmpty {
                VStack(alignment: .leading) {
                    Text("選択されたテーマ:")
                        .font(.headline)
                    ForEach(DecidedTheme, id: \.self) { theme in
                        Text("• \(theme)")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    func removeTheme(theme: String) {
        if let index = favoriteThemes.firstIndex(of: theme) {
            favoriteThemes.remove(at: index)
        }
    }
}

struct NewsView: View {
    @State private var searchQuery = ""
    @State private var newsResults: [NewsArticle] = []
    @State private var selectedArticle: NewsArticle?
    @State private var generatedThemes: [String] = []
    @State private var selectedThemes: [String] = []
    @State private var isLoading = false
    
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                TextField("ニュースを検索", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await searchNews()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            // Display news results
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(newsResults, id: \.url) { article in
                        Button(action: {
                            selectedArticle = article
                            Task {
                                await generateThemes(from: article)
                            }
                        }) {
                            Text(article.title)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            
            // Display selected news content if available
            if let article = selectedArticle {
                VStack(alignment: .leading, spacing: 10) {
                    Text("選択したニュース:")
                        .font(.headline)
                    
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Display the URL as a clickable link
                    Link("リンクを表示", destination: URL(string: article.url)!)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            
            // Display generated themes if available
            if !generatedThemes.isEmpty {
                VStack(alignment: .leading) {
                    Text("生成されたテーマ:")
                        .font(.headline)
                    ForEach(generatedThemes, id: \.self) { theme in
                        Button(action: {
                            toggleTheme(theme)
                        }) {
                            Text(theme)
                                .padding()
                                .background(selectedThemes.contains(theme) ? Color.green : Color.gray.opacity(0.2))
                                .foregroundColor(selectedThemes.contains(theme) ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("ニュース")
    }
    
    func searchNews() async {
        if let articles = fetchNews(keyword: searchQuery) {
            var updatedResults: [NewsArticle] = []
            for article in articles {
                if let url = article["url"], let content = await getNewsContent(url: URL(string: url)!) {
                    let newsArticle = NewsArticle(title: article["title"] ?? "", url: url, content: content)
                    updatedResults.append(newsArticle)
                }
            }
            DispatchQueue.main.async {
                self.newsResults = updatedResults
            }
        }
    }
    
    func generateThemes(from article: NewsArticle) async {
        let content = article.content
        topic_generator(content: content) { topics in
            if let generatedTopics = topics {
                self.generatedThemes = generatedTopics
            } else {
                print("テーマ生成に失敗しました")
            }
        }
    }
    
    func toggleTheme(_ theme: String) {
        if selectedThemes.contains(theme) {
            selectedThemes.removeAll { $0 == theme }
        } else {
            selectedThemes.append(theme)
        }
    }
}


// Ensure NewsArticle has the content property
struct NewsArticle {
    let title: String
    let url: String
    let content: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
