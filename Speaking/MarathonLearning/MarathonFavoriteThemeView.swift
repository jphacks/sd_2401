import SwiftUI
import Foundation
import SwiftSoup

struct MarathonFavoriteThemesView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    @State private var newTheme = ""
    @State private var showGeneratedThemes = false
    @State private var generatedThemes: [String] = []
    @ObservedObject var themeManager: ThemeManager
    
    let repetitions: Int
    @Binding var isNavigationActive: Bool
    
    var body: some View {
        ZStack {
            // 背景画像を全体に適用
            Image("back")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // コンテンツ全体をスクロール可能に
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // テーマリストと新しいテーマ追加
                    VStack(alignment: .leading) {
                        Text("好きなテーマ")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(favoriteTopicsManager.favoritetopics, id: \.self) { theme in
                                ZStack(alignment: .topLeading) {
                                    Text(theme)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Image("back"))
                                        .foregroundColor(Color("icon_color"))
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                    
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
                                    .foregroundColor(Color("icon_color"))
                                    .padding(.vertical, 8)
                                    .background(Image("back"))
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding()
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                }
                .padding()
                .background(Image("pokepoke"))
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
                
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
                        
                        ForEach(generatedThemes, id: \ .self) { theme in
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
                if !themeManager.DecidedTheme.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("  選択されたテーマ:")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.7))
                        
                        ForEach(themeManager.DecidedTheme, id: \.self) { theme in
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
                                .overlay(
                                    // 左上に削除ボタンを配置
                                    Button(action: {
                                        toggleTheme(theme)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .padding(1)
                                    },
                                    alignment: .topLeading
                                )
                                .frame(maxWidth: .infinity)
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
                
            
            }
        }
    }
    
    // 既存の関数
    func addNewTheme() {
        if !newTheme.isEmpty {
            favoriteTopicsManager.favoritetopics.append(newTheme)
            newTheme = ""
        }
    }
    
    func generateTopics() {
        themeManager.DecidedTheme = [] // DecidedThemeをリセット
        
        let content = favoriteTopicsManager.favoritetopics.joined(separator: ", ")
        
        topic_generator(content: content) { topics in
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
    
    func removeTheme(theme: String) {
        if let index = favoriteTopicsManager.favoritetopics.firstIndex(of: theme) {
            favoriteTopicsManager.favoritetopics.remove(at: index)
        }
    }
}

