import SwiftUI

struct ImageThemeGenerationView: View {
    @State private var inputImage: UIImage?
    @State private var generatedThemes: [String] = []
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var DecidedTheme: [String] = []
    @State private var themeHints: [String: String] = [:] // 各テーマのヒントを保持
    
    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("画像テーマ生成")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.top, 50)
                    
                    if let image = inputImage {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .cornerRadius(10)
                                .overlay(
                                    Text("画像を選択")
                                        .foregroundColor(.gray)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("画像を選択")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Image("pokepoke"))
                            .foregroundColor(Color("icon_color"))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $inputImage)
                    }
                    
                    Button(action: {
                        generateThemesFromImage()
                    }) {
                        Text("テーマ生成")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                inputImage != nil
                                ? AnyView(Image("pokepoke2").resizable().scaledToFill())
                                : AnyView(Color.gray.opacity(0.9))
                            )
                            .foregroundColor(
                                inputImage != nil
                                ? Color("icon_color")
                                : .white
                            )
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    .disabled(inputImage == nil || isLoading)
                    
                    if isLoading {
                        ProgressView("テーマ生成中...")
                            .padding()
                    }
                    
                    if !generatedThemes.isEmpty {
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
                                            .frame(maxWidth: .infinity)
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
                        VStack(alignment: .leading, spacing: 5) {
                            Text("スピーチテーマ:")
                                .font(.headline)
                            
                            VStack {
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
                                            
                                            // ヒント生成ボタンを選択されたテーマに追加
                                            Button(action: {
                                                if let _ = themeHints[theme] {
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
                                        
                                        // ヒントの表示
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
                        }
                        .padding(.horizontal)
                    }
                    
                    MicSubmitView(decidedTheme: $DecidedTheme)
                        .padding(.top, 20)
                }
                .padding()
                .background(
                    Image("back")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
            }
        }
    }
    
    func generateThemesFromImage() {
        guard let image = inputImage else { return }
        isLoading = true
        
        let prompt = """
        ・以下の画像を分析し、画像の内容に基づいてスピーチに適した5つのテーマを日本語で生成してください。
        ・スピーチテーマは短くしてください
        ・スピーチテーマは簡単にしてください（高校生レベル）   
        ・ユニークで面白いテーマだと良いです
        ・超重要：画像から読み取れる固有名詞(ゲームや人名、場所など)やキャラクターの情報(関連の情報など)、IPなどを必ずテーマに含めてください。
        ・回答はスピーチテーマだけを日本語で提供してください。
        ・回答のしやすいものを上に、難しいまたは複雑な回答を下に出力するようにしてください。
        ・テーマの文字列のみを出力してください。
        [出力の形式]
            <topic>
            <topic>
            <topic>
            <topic>
            <topic>
        """
        
        ImageManager.shared.requestImageAnalysis(image: image, prompt: prompt) { themes in
            DispatchQueue.main.async {
                if let themes = themes {
                    self.generatedThemes = themes
                } else {
                    self.generatedThemes = ["テーマ生成に失敗しました"]
                }
                self.isLoading = false
            }
        }
    }
    
    func toggleTheme(_ theme: String) {
        if DecidedTheme.contains(theme) {
            DecidedTheme.removeAll { $0 == theme }
            themeHints.removeValue(forKey: theme) // ヒントも削除
        } else {
            DecidedTheme.append(theme)
        }
    }
}

