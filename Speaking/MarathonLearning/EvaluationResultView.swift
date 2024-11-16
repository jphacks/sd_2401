import SwiftUI
import Charts

struct SimpleEvaluationResultView: View {
    let pronunciation: Double
    let fluency: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Text("簡易評価結果")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // スコアの棒グラフ
            Chart {
                BarMark(
                    x: .value("Category", "Pronunciation"),
                    y: .value("Score", pronunciation)
                )
                BarMark(
                    x: .value("Category", "Fluency"),
                    y: .value("Score", fluency)
                )
            }
            .frame(height: 300)
            
            // スコアの数値表示
            VStack(alignment: .leading, spacing: 10) {
                Text("Pronunciation: \(pronunciation, specifier: "%.2f")")
                Text("Fluency: \(fluency, specifier: "%.2f")")
            }
            .font(.headline)
            
            Text("よくできました！")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
        }
        .padding()
    }
}

