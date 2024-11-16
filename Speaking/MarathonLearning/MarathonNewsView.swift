import SwiftUI
import Foundation
import SwiftSoup


struct MarathonNewsView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    @State private var searchQuery = ""
    @State private var newsResults: [NewsArticle] = []
    @State private var selectedArticle: NewsArticle?
    @State private var generatedThemes: [String] = []
    //@State private var selectedThemes: [String] = []
    @State private var isLoading = false
    @State private var extractedKeywords: [String] = []
    @State private var hasSearched = false // 新たに追加
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    let repetitions: Int
    @Binding var isNavigationActive: Bool
    
    var body: some View {
        VStack {
            // 検索バー
            HStack {
                TextField("ニュースを検索", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        hasSearched = true // 検索が行われたことを記録
                        await searchNews()
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
            
            
            // ニュース記事のリスト表示
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    // 検索結果がない場合の表示
                    if newsResults.isEmpty {
                        Text("検索結果がありません")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black.opacity(0.5))
                    }
                    
                    
                    ForEach(newsResults, id: \.url) { article in
                        let isSelected = selectedArticle?.id == article.id
                        
                        Button(action: {
                            selectedArticle = article
                        }) {
                            HStack(spacing: 10) {
                                // チェックマーク表示（選択されている場合のみ）
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                
                                // 画像表示
                                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 40, height: 40)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipped()
                                                .cornerRadius(5)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .frame(width: 40, height: 40)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(5)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .frame(width: 40, height: 40)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(5)
                                }
                                
                                // タイトル表示
                                Text(article.title)
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            .padding(.horizontal, 10)
                            .background(isSelected ? Color.mint.opacity(0.25) : Color.purple.opacity(0.08))
                            .cornerRadius(8)
                        }
                    }
                    
                    
                    
                    
                    
                    if let article = selectedArticle {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(spacing: 10) {
                                // 画像表示
                                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 160)
                                                .clipped()
                                                .cornerRadius(10)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .frame(height: 200)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(10)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(height: 200)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                // タイトル表示
                                Text(article.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.top, 5)
                            }
                            .padding(.horizontal, 10)
                            .cornerRadius(8)
                            
                            // URLのリンク表示
                            if let url = URL(string: article.url) {
                                Link("   [記事を全文読む]    ", destination: url)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            } else {
                                Text("無効なURLです")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            
                            // テーマ生成ボタン
                            Button(action: {
                                isLoading = true
                                Task {
                                    await generateThemes(from: article)
                                    isLoading = false
                                }
                            }) {
                                Text("スピーチテーマの生成")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Image("tab_image"))
                                    .foregroundColor(.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            
                            // キーワード表示ボタン
                            Button(action: {
                                isLoading = true
                                extractKeywords(title: article.title, body: article.content ?? "") { keywords in
                                    DispatchQueue.main.async {
                                        self.isLoading = false
                                        if let keywords = keywords {
                                            self.extractedKeywords = keywords
                                        } else {
                                            print("キーワードの抽出に失敗しました")
                                        }
                                    }
                                }
                            }) {
                                Text("記事のキーワード")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Image("pokepoke2"))
                                    .foregroundColor(.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    
                    
                    
                    // 生成されたテーマの表示
                    if !generatedThemes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("生成テーマの一覧:")
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
                                            .frame(maxWidth: .infinity)
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
                    
                    // 抽出されたキーワードの表示
                    if !extractedKeywords.isEmpty {
                        let columns = [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 8) {
                            Text("記事のキーワード:")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                            
                            ForEach(extractedKeywords.prefix(8), id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(.white.opacity(0.2))
                                    .foregroundColor(.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding()
                        .background(Image("pokepoke2"))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
                
                // 選択されたテーマをマイクボタンの上に表示
                if !themeManager.DecidedTheme.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("スピーチテーマ:")
                            .font(.headline)
                        VStack {
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
                    }
                    .padding(.horizontal)
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
            
            // ローディングインジケータ
            if isLoading {
                ProgressView("処理中...")
                    .padding()
            }
            
        }
        .navigationTitle("ニュース")
        .background(
            Image("back")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
    
    // 関数の定義
    func searchNews() async {
        if let articles = await fetchNews(keyword: searchQuery) {
            var updatedResults: [NewsArticle] = []
            for articleData in articles {
                if let url = articleData["url"] as? String,
                   let title = articleData["title"] as? String {
                    let imageURL = articleData["imageURL"] as? String
                    var newsArticle = NewsArticle(title: title, url: url, imageURL: imageURL)
                    
                    if let content = await fetchArticleContent(url: url) {
                        newsArticle.content = content
                    }
                    updatedResults.append(newsArticle)
                }
            }
            DispatchQueue.main.async {
                self.newsResults = updatedResults
            }
        } else {
            print("ニュース記事の取得に失敗しました")
        }
    }
    
    func generateThemes(from article: NewsArticle) async {
        guard let contents = article.content else {
            print("記事のコンテンツがありません")
            isLoading = false
            return
        }
        topic_generator(content: contents, isNews: true) { (topics: [String]?) in
            DispatchQueue.main.async {
                if let generatedTopics = topics {
                    self.themeManager.DecidedTheme = []
                    self.generatedThemes = generatedTopics
                } else {
                    print("テーマ生成に失敗しました")
                }
            }
        }
    }
    
    func fetchArticleContent(url: String) async -> String? {
        guard let articleURL = URL(string: url) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: articleURL)
            if let html = String(data: data, encoding: .utf8) {
                let doc: Document = try SwiftSoup.parse(html)
                let paragraphs: Elements = try doc.select("p")
                let content = try paragraphs.text()
                return content
            }
        } catch {
            print("記事のコンテンツ取得エラー: \(error.localizedDescription)")
            return nil
        }
        return nil
    }
    
    func extractKeywords(title: String, body: String, focus: String = "ORG", completion: @escaping ([String]?) -> Void) {
        let url = URL(string: "https://labs.goo.ne.jp/api/keyword")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "app_id": Config.goo_lab_APIkey,
            "title": title,
            "body": body,
            "max_num": 7,
            "focus": focus
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("リクエストボディの作成に失敗しました")
            completion(nil)
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("エラーが発生しました: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("データがありません")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let dictionary = json as? [String: Any],
               let keywordsArray = dictionary["keywords"] as? [[String: Double]] {
                var keywords: [String] = []
                for keywordDict in keywordsArray {
                    if let keyword = keywordDict.keys.first {
                        keywords.append(keyword)
                    }
                }
                completion(keywords)
            } else {
                print("レスポンスのパースに失敗しました")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func toggleTheme(_ theme: String) {
        if themeManager.DecidedTheme.contains(theme) {
            themeManager.DecidedTheme.removeAll { $0 == theme }
        } else {
            themeManager.DecidedTheme.append(theme)
        }
    }
}

