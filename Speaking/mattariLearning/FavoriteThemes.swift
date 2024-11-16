import SwiftUI
import Foundation

struct FavoriteThemesView: View {
    @State private var favoriteThemes = ["ゲーム"]
    @State private var newTheme = ""
    @State private var showGeneratedThemes = false
    @State private var generatedThemes: [String] = []
    @State private var DecidedTheme: [String] = []
    @State private var themeHints: [String: String] = [:] // 各テーマのヒントを保存
    
    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // テーマリストと新しいテーマ追加
                    VStack(alignment: .leading) {
                        Text("好きなテーマ")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(favoriteThemes, id: \.self) { theme in
                                ZStack(alignment: .topLeading) {
                                    Button(action: {
                                        removeTheme(theme: theme)
                                    }) {
                                        Text(theme)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Image("back"))
                                            .foregroundColor(Color("icon_color"))
                                            .cornerRadius(10)
                                            .shadow(radius: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // テキストボタンとして動作
                                    
                                    // マイナスサークルボタンを左上に残す
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
                                    
                                    Button(action: {
                                        // ヒントが既に存在する場合は削除し、なければ生成
                                        if themeHints[theme] != nil {
                                            themeHints.removeValue(forKey: theme)
                                        } else {
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
                
                MicSubmitView(decidedTheme: $DecidedTheme)
                    .padding(.top, 20)
            }
        }
    }
    
    func addNewTheme() {
        if !newTheme.isEmpty {
            favoriteThemes.append(newTheme)
            newTheme = ""
        }
    }
    
    func generateTopics() {
        DecidedTheme = []
        
        let content = favoriteThemes.joined(separator: ", ")
        
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
        if DecidedTheme.contains(theme) {
            DecidedTheme.removeAll { $0 == theme }
            themeHints.removeValue(forKey: theme)
        } else {
            DecidedTheme.append(theme)
        }
    }
    
    func removeTheme(theme: String) {
        if let index = favoriteThemes.firstIndex(of: theme) {
            favoriteThemes.remove(at: index)
        }
    }
}

