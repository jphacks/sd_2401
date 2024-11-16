import SwiftUI
import Charts
import Foundation

struct MarathonSetupView: View {
    @State private var repetitions = 5
    @State private var repetitionCount = 0
    @StateObject private var favoriteTopicsManager = FavoriteTopicsManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    @StateObject private var tabManager = TabManager()
    @StateObject private var repetitionManager = RepetitionManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject var scoreManager = ScoreManager()
    @StateObject var logScoreManager = LogScoreManager()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("マラソンラーニングの説明")
                        .font(.headline)
                    
                    Text("このモードは集中的にスピーチ能力を向上させたい人向けです。各ステップで時間制限が設けられており、テンポよく学習が行えます。")
                    Spacer()
                    
                    TextField("繰り返し回数", value: $repetitions, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                    
                    NavigationLink(destination: CheckLogView(logScoreManager: logScoreManager)
                        ) {
                            Text("過去の記録を見る")
                                .font(.title)
                                .padding()
                                .foregroundColor(Color.blue)
                                .cornerRadius(8)
                        }
                    
                    NavigationLink(destination: MarathonDecideThemeView(tabManager: tabManager, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager, favoriteTopicsManager: favoriteTopicsManager, themeManager: themeManager, repetitions: repetitions)
                        .navigationBarBackButtonHidden(true)) {
                            Text("開始")
                                .font(.title)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    
                }
                .padding()
            }
        }

        .navigationBarTitleDisplayMode(.inline)
        .background(
            Image("back") // 画像名に応じて変更
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
        )
    }
}

class RepetitionManager: ObservableObject {
    @Published var repetitionCount: Int = 0
}

// ユーザーが直前に選択したテーマを保持しておく
class ThemeManager: ObservableObject {
    @Published var DecidedTheme: [String] = []
}

// ユーザーが得点したスコアを保持しておく
class ScoreManager: ObservableObject {
    @Published var scores: [Int] = []
    
    func addScore(_ score: Int) {
        scores.append(score)
    }
}


// ユーザーが直前にどのタブにいたかを覚えておく
class TabManager: ObservableObject {
    @Published var selectedTabIndex: Int = 0 // Default tab index, can be modified as needed
}

// 好きなテーマモードのトピックを覚えておく
class FavoriteTopicsManager: ObservableObject {
    @Published var favoritetopics = ["ゲーム", "フード", "モンハン", "アニメ"]
}

