import SwiftUI
import Foundation

struct MicSubmitView: View {
    @State private var isRecording = false
    @State private var canNavigate = false
    @State private var showAlert = false
    @State private var minAudioDuration: Double = 0
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    
    @Binding var decidedTheme: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Mic Button
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    canNavigate = false
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
            }) {
                VStack {
                    Image(systemName: "mic.circle.fill")
                        .opacity(isRecording ? 1 : 0.8)
                        .background(Color.clear) // 透明な背景
                        .foregroundColor(isRecording ? .red : .blue.opacity(0.8))
                        .font(.system(size: 80))
                    Text(isRecording ? "録音中..." : "録音開始")
                        .foregroundColor(.black.opacity(0.7))
                        .font(.headline)
                }
            }
            .background(Color.clear) // 透明な背景
            .cornerRadius(20)

            // Submit Button
            if canNavigate {
                NavigationLink(destination: EvaluateView(audioFileURL: speechManager.audioFileURL, textFileURL: speechManager.textFileURL, decidedTheme: decidedTheme)) {
                    Text("音声の提出")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(width: 200)
            } else {
                Button(action: {
                    showAlert = true
                }) {
                    Text("音声の提出")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.gray.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(width: 200)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("エラー"), message: Text("指定した時間以上の音声が保存されていません。").foregroundColor(Color("font_color")), dismissButton: .default(Text("OK")))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
