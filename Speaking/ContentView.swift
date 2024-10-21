import SwiftUI
import Combine

struct ContentView: View {
    @State private var favoriteThemes = ["ゲーム", "フード", "モンハン", "アニメ"]
    @State private var newTheme = ""
    @State private var selectedMode: String? = "好きなテーマ"
    @State private var showGeneratedThemes = false
    @State private var selectedTheme: String? = nil // 選択されたテーマを保持
    @State private var isMicActive = false // マイクの状態を保持
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ScrollView { // ScrollViewでラップして全体をスクロール可能に
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
                        YoutubeView()
                    } else if selectedMode == "News" {
                        NewsView()
                    }
                    
                    Spacer()
                    
                    // Theme Generation Button
                    Button(action: {
                        showGeneratedThemes.toggle()
                    }) {
                        Text("テーマ生成")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    // Show Generated Themes as Buttons
                    if showGeneratedThemes {
                        VStack(alignment: .leading) {
                            ForEach(favoriteThemes, id: \.self) { theme in
                                Button(action: {
                                    selectedTheme = theme // テーマを選択
                                }) {
                                    Text(theme)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Display selected theme
                    if let selectedTheme = selectedTheme {
                        Text("テーマ: \(selectedTheme)")
                            .padding()
                            .font(.headline)
                    }
                    
                    // Mic Button
                    Button(action: {
                        isMicActive.toggle() // ボタンを押すたびに赤/黒を切り替え
                    }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(isMicActive ? .red : .black) // 状態に応じて色を変更
                            .font(.system(size: 40))
                    }
                    .padding()
                    
                }
                .padding(.bottom, keyboardHeight) // キーボードの高さに応じて下部にパディングを追加
                .onAppear {
                    self.subscribeToKeyboardEvents() // キーボードのイベントを購読
                }
                .onDisappear {
                    NotificationCenter.default.removeObserver(self) // 不要になったら解除
                }
            }
            .navigationTitle("モード選択")
        }
    }
    
    func addNewTheme() {
        if !newTheme.isEmpty {
            favoriteThemes.append(newTheme)
            newTheme = ""  // TextFieldの内容をリセット
        }
    }
    
    // キーボード表示時のイベントを購読
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

// View for "好きなテーマ"
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
                    Text(theme)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
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
}

// View for "Youtube"
struct YoutubeView: View {
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Youtubeのテーマ")
                    .font(.headline)
                // Add more content related to Youtube here
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
}

// View for "News"
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

