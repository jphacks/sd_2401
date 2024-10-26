import SwiftUI
import Combine
import AVFoundation

struct ContentView: View {
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
        NavigationView {
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
                        FavoriteThemesView(favoriteThemes: $favoriteThemes, newTheme: $newTheme, addNewTheme: addNewTheme)
                    } else if selectedMode == "Youtube" {
                        YoutubeView(searchQuery: $searchQuery, searchResults: $searchResults, selectedVideo: $selectedVideo, youtubeSearchService: youtubeSearchService, captionText: $captionText)
                    } else if selectedMode == "News" {
                        NewsView()
                    }
                    
                    Spacer()
                    
                    // Theme Generation Button
                    Button(action: {
                        generateTopics()
                    }) {
                        Text("テーマ生成")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    // 生成されたテーマの表示
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
                    
                    // 選択されたテーマの表示
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
                    
                    // Mic Button
                    Button(action: {
                        isRecording.toggle()
#if !targetEnvironment(simulator)
                        if isRecording {
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
#endif
                    }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(isRecording ? .red : .black)
                            .font(.system(size: 40))
                    }
                    .padding()
                    
                    // Evaluate and Navigation
                    if canNavigate {
                        NavigationLink(destination:  EvaluateView(audioFileURL: speechManager.audioFileURL, textFileURL: speechManager.textFileURL)) {
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
    
    var body: some View {
        VStack {
            TextField("検索ワードを入力", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                youtubeSearchService.searchYoutubeVideos(query: searchQuery) { results in
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
                                    } else {
                                        self.selectedVideo = nil
                                    }
                                }
                            ))
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct FavoriteThemesView: View {
    @Binding var favoriteThemes: [String]
    @Binding var newTheme: String
    var addNewTheme: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("好きなテーマ")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(favoriteThemes, id: \.self) { theme in
                    ZStack(alignment: .topLeading){
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
    var body: some View {
        ZStack {
            Color.orange.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Newsのテーマ")
                    .font(.headline)
                // Add more content related to News here
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
