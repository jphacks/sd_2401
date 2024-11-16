import Foundation
import SwiftUI
import Charts
import UIKit

// LogScoreManager: 継続率とスコアを管理するクラス
class LogScoreManager: ObservableObject {
    @Published private(set) var recentAverageScores: [Int] = []
    @Published private(set) var continuationDays: [Bool] = Array(repeating: false, count: 7)  // 直近7日間の出席状況
    @Published var rankScore: Int = 0  // 継続率得点を含むランクスコア
    
    private var lastUpdateTimestamp: Date?  // 最後に更新した時間
    
    init() {
        self.recentAverageScores = loadRecentAverageScores()
        self.continuationDays = loadContinuationDays()
        self.lastUpdateTimestamp = loadLastUpdateTimestamp()
        adjustContinuationDaysIfNeeded()  // 初期化時に出席記録を調整
        updateRankScore()  // 初期化時にランクスコアを更新
    }
    
    // 外部から渡された平均スコアをrecentAverageScoresに追加
    func addAverageScore(_ score: Int) {
        recentAverageScores.append(score)
        
        if recentAverageScores.count > 7 {
            recentAverageScores.removeFirst()
        }
        
        saveRecentAverageScores()
        updateRankScore()  // スコアが追加されたらランクスコアを更新
    }
    
    // 平均スコアを追加し保存する recordScore メソッド
    func recordScore(_ score: Int) {
        addAverageScore(score)
        if canUpdateContinuationDays() {
            updateContinuationDays()
        }
        updateRankScore()  // 継続日数が更新されたらランクスコアも再計算
    }
    
    // 過去7日間の出席状況に基づいた得点計算（0-100点を返す）
    private func calculateContinuityScore() -> Int {
        let attendanceCount = continuationDays.filter { $0 }.count
        switch attendanceCount {
        case 7: return 100  // 7日出席
        case 5...6: return 80  // 5〜6日出席
        case 3...4: return 60  // 3〜4日出席
        case 1...2: return 40  // 1〜2日出席
        default: return 0  // それ以下は0点
        }
    }
    
    // ランクスコアを更新
    private func updateRankScore() {
        let averageScore = recentAverageScores.isEmpty ? 0 : recentAverageScores.reduce(0, +) / recentAverageScores.count
        let continuityScore = calculateContinuityScore()
        rankScore = averageScore + continuityScore  // 平均点と継続スコアの合計をrankScoreに設定
    }
    
    // 出席状況を更新するメソッド
    private func updateContinuationDays() {
        continuationDays.append(true)
        print(continuationDays)
        
        if continuationDays.count >= 7 {
            continuationDays.removeFirst()
        }
        
        saveContinuationDays()
        saveLastUpdateTimestamp(Date())  // 更新時に現在の時間を保存
    }
    
    // 最後の更新から複数日経過している場合に出席記録を調整
    private func adjustContinuationDaysIfNeeded() {
        guard let lastUpdate = lastUpdateTimestamp else { return }
        
        let currentTime = Date()
        let daysSinceLastUpdate = Int(currentTime.timeIntervalSince(lastUpdate) / (24 * 60 * 60))
        
        if daysSinceLastUpdate > 0 {
            continuationDays = Array(continuationDays.dropFirst(min(daysSinceLastUpdate, continuationDays.count)))
            continuationDays.append(contentsOf: Array(repeating: false, count: daysSinceLastUpdate))
            if continuationDays.count > 7 {
                continuationDays = Array(continuationDays.suffix(7))
            }
            
            saveContinuationDays()
            saveLastUpdateTimestamp(currentTime)
        }
    }
    
    // 24時間経過しているかチェック
    private func canUpdateContinuationDays() -> Bool {
        guard let lastUpdate = lastUpdateTimestamp else {
            return true  // 初回更新は許可
        }
        
        let currentTime = Date()
        let timeDifference = currentTime.timeIntervalSince(lastUpdate)
        
        return timeDifference >= 24 * 60 * 60  // 24時間以上経過しているか
        // return timeDifference >= 60
    }
    
    // 保存・読み込み処理
    private func saveRecentAverageScores() {
        UserDefaults.standard.set(recentAverageScores, forKey: "recentAverageScores")
    }
    
    private func loadRecentAverageScores() -> [Int] {
        return UserDefaults.standard.array(forKey: "recentAverageScores") as? [Int] ?? []
    }
    
    private func saveContinuationDays() {
        UserDefaults.standard.set(continuationDays, forKey: "continuationDays")
    }
    
    private func loadContinuationDays() -> [Bool] {
        return UserDefaults.standard.array(forKey: "continuationDays") as? [Bool] ?? Array(repeating: false, count: 7)
    }
    
    // 最後に更新した時間を保存・読み込み
    private func saveLastUpdateTimestamp(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "lastUpdateTimestamp")
    }
    
    private func loadLastUpdateTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: "lastUpdateTimestamp") as? Date
    }
}

// CheckLogView: ログスコアや統計を表示するビュー
struct CheckLogView: View {
    @ObservedObject var logScoreManager: LogScoreManager
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage? = nil
    @State private var userText: String = ""
    
    // 背景を表示するメソッド
    private func backgroundForRankScore() -> Image {
        switch logScoreManager.rankScore {
        case 251...:
            return Image("gold")
        case 201...250:
            return Image("silver")
        case 151...200:
            return Image("bronze")
        default:
            return Image("blue")
        }
    }
    
    private func rankText() -> String {
        switch logScoreManager.rankScore {
        case 251...:
            return "Your Rank is Gold"
        case 201...250:
            return "Your Rank is Silver"
        case 151...200:
            return "Your Rank is Bronze"
        default:
            return "Your Rank is Blue"
        }
    }
    
    var body: some View {
        ZStack {
            backgroundForRankScore()
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Text(rankText())
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.black)
                    .padding()
                    .padding(.top, 40)
                    .font(.system(.largeTitle, design: .serif))
                
                Spacer()
                Text("Recent Average Scores")
                    .font(.headline)
                    .padding()
                    .font(.system(.title, design: .serif))
                
                Chart {
                    ForEach(Array(logScoreManager.recentAverageScores.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("Attempt", index + 1),
                            y: .value("Rank Score", score)
                        )
                        .symbol(Circle())
                        .foregroundStyle(Color.red)
                    }
                }
                .chartYScale(domain: 0...200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)")
                                .foregroundColor(.black)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)")
                                .foregroundColor(.black)
                        }
                    }
                }
                .frame(width: (UIScreen.main.bounds.width) * 3 / 4, height: 200)
                .padding()
                
                Spacer()
                
                Text("continuationDays in Last 7 Days: \(logScoreManager.continuationDays.filter { $0 }.count)")
                    .font(.system(.body, design: .serif))
                    .padding(.top, 10)
                
                Spacer()
                
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
            }
            .padding(.bottom, 20)
        }
    }
    
    private func captureView(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let rendered = ImageRenderer(content: ZStack {
                backgroundForRankScore()
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    Spacer()
                    Text(rankText())
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                        .padding()
                        .padding(.top, 40)
                    
                    Spacer()
                    Text("Recent Average Scores")
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .padding()
                    
                    Chart {
                        ForEach(Array(logScoreManager.recentAverageScores.enumerated()), id: \.offset) { index, score in
                            LineMark(
                                x: .value("Attempt", index + 1),
                                y: .value("Rank Score", score)
                            )
                            .symbol(Circle())
                            .foregroundStyle(Color.red)
                        }
                    }
                    .chartYScale(domain: 0...200)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                                    .foregroundColor(.black)
                                    .font(.custom("Avenir Next", size: 16))  // 軸ラベルにもスタイリッシュなフォント
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                                    .foregroundColor(.black)
                                    .font(.custom("Avenir Next", size: 16))  // 軸ラベルにスタイリッシュなフォント
                            }
                        }
                    }
                    .frame(width: (UIScreen.main.bounds.width) , height: 300)
                    .padding()
                    
                    Spacer()
                    
                    Text("continuationDays in Last 7 Days: \(logScoreManager.continuationDays.filter { $0 }.count)")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .padding(.top, 10)
                    
                    Spacer()
                    
                }
                .padding(.bottom, 20)
            })
            
            if let image = rendered.uiImage {
                self.renderedImage = image
                completion()
            }
        }
    }
}

