import SwiftUI

struct EndView: View {
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    @State private var userText: String = ""
    
    var averageScore: Int {
        guard !scoreManager.scores.isEmpty else { return 0 }
        let total = scoreManager.scores.reduce(0, +)
        return total / scoreManager.scores.count
    }
    
    var highestScore: Int {
        scoreManager.scores.max() ?? 0
    }
    
    private var backgroundImageName: String {
        switch averageScore {
        case ..<101:
            return "blue"
        case 101...125:
            return "bronze"
        case 126...150:
            return "silver"
        default:
            return "gold"
        }
    }
    
    var body: some View {
        ZStack {
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    Text("Your score data")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .padding()
                    
                    Text("average: \(averageScore) max: \(highestScore)")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .padding()
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(scoreManager.scores, id: \.self) { score in
                            VStack {
                                Text("\(score)")
                                    .font(.caption)
                                    .rotationEffect(.degrees(-45))
                                    .padding(.bottom, 4)
                                
                                Rectangle()
                                    .fill(score >= 150 ? Color.green : score >= 100 ? Color.yellow : Color.red)
                                    .frame(width: 20, height: CGFloat(score))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .cornerRadius(8)
            
                
                Button(action: {
                    captureView {
                        showShareSheet = true
                    }
                }) {
                    Text("Share")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
                .sheet(isPresented: $showShareSheet) {
                    if let renderedImage = renderedImage {
                        ShareSheet(activityItems: [userText, renderedImage])
                    }
                }
                
                NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true)) {
                    Text("モード選択に戻る")
                        .padding()
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .onAppear {
            logScoreManager.recordScore(averageScore)
        }
    }

    
    // キーボードを閉じるメソッド
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // キャプチャするビューの背景
    private func captureView(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            // `averageScore` に応じて背景画像を変更
            let backgroundImageName: String
            switch averageScore {
            case ..<101:
                backgroundImageName = "blue"
            case 101...125:
                backgroundImageName = "bronze"
            case 126...150:
                backgroundImageName = "silver"
            default:
                backgroundImageName = "gold"
            }
            
            // ImageRendererで背景画像とコンテンツをキャプチャ
            let renderer = ImageRenderer(content: VStack {
                ZStack {
                    Image(backgroundImageName)
                        .resizable()
                        .scaledToFill() // 画面全体にフィットさせる
                        .ignoresSafeArea() // 全画面表示
                    
                    // キャプチャするビューの内容
                    VStack(spacing: 40) {  // 余白を調整して全体を大きく表示
                        Text("Your Score Data")
                            .font(.system(size: 48, weight: .bold, design: .serif)) // フォントサイズをさらに大きく
                            .padding(.bottom, 24)
                        
                        Text("Average: \(averageScore)  Max: \(highestScore)")
                            .font(.system(size: 36, weight: .medium, design: .serif)) // フォントサイズをさらに大きく
                            .padding(.bottom, 30)
                        
                        // グラフの表示部分
                        HStack(alignment: .bottom, spacing: 20) {
                            ForEach(scoreManager.scores, id: \.self) { score in
                                VStack {
                                    Text("\(score)")
                                        .font(.system(size: 20))
                                        .rotationEffect(.degrees(-45))
                                        .padding(.bottom, 12)
                                    
                                    Rectangle()
                                        .fill(score >= 150 ? Color.green : score >= 100 ? Color.yellow : Color.red)
                                        .frame(width: 40, height: CGFloat(score) * 2) // 幅と高さをさらに拡大
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                    }
                    .padding()
                }
            })
            
            if let uiImage = renderer.uiImage {
                renderedImage = uiImage
                completion()
            }
        }
    }
}

// UIViewControllerRepresentableでUIActivityViewControllerを作成
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// ImageRenderer: SwiftUIのViewをUIImageに変換
struct ImageRenderer<Content: View> {
    let content: Content
    
    var uiImage: UIImage? {
        let controller = UIHostingController(rootView: content)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}


