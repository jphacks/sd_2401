import SwiftUI

struct MarathonRecordView: View {
    @State private var isRecording = false
    @State private var canNavigate = false
    @State private var showAlert = false
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    @State private var captionText: String = ""
    @State private var minAudioDuration: Double = 0
    
    @ObservedObject var tabManager: TabManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var favoriteTopicsManager: FavoriteTopicsManager
    let repetitions: Int
    @ObservedObject var repetitionManager: RepetitionManager
    @ObservedObject var scoreManager: ScoreManager
    @ObservedObject var logScoreManager: LogScoreManager
    
    // Thinking Timer Properties
    @State private var thinkingTimeLeft = 120
    @State private var thinkingTimerActive = true
    @State private var thinkingTimer: Timer? = nil
    
    @State private var isExitNavigationActive: Bool = false
    
    var body: some View {
            ZStack {
                Image("back") // 画像名に応じて変更
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    Text("Thinking and recording Time: \(thinkingTimeLeft)s")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                    
                    Text(themeManager.DecidedTheme.joined(separator: ", "))
                        .padding()
                    
                    NavigationLink(destination: ContentView()
                        .navigationBarBackButtonHidden(true), isActive: $isExitNavigationActive) {
                            EmptyView()
                        }
                    
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
                    
                    if canNavigate {
                        NavigationLink(destination: MarathonEvaluateView(audioFileURL: speechManager.audioFileURL, textFileURL: speechManager.textFileURL, tabManager: tabManager, themeManager: themeManager, favoriteTopicsManager: favoriteTopicsManager, repetitions: repetitions, repetitionManager: repetitionManager, scoreManager: scoreManager, logScoreManager: logScoreManager).navigationBarBackButtonHidden(true)) {
                            Text("音声の提出")
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: { showAlert = true }) {
                            Text("音声の提出")
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("エラー"), message: Text("指定した時間以上の音声が保存されていません。"), dismissButton: .default(Text("OK")))
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(trailing: Button("終了") {
                    isExitNavigationActive = true
                })
                .onAppear {
                    startThinkingTimer()
                }
            }
    }
    
    
    func startOrStopRecording() {
        thinkingTimerActive = false // Disable thinking timer if manually started
        isRecording.toggle()
        
        if isRecording {
            canNavigate = false
            speechManager.startRecording()
        } else {
            stopRecordingAndEvaluate()
        }
        
    }
    
    func stopRecordingAndEvaluate() {
        isRecording.toggle()
        speechManager.stopRecording()
        speechManager.transcribeAudioFile { success in
            guard success, let audioURL = speechManager.audioFileURL, let textURL = speechManager.textFileURL else {
                canNavigate = false
                return
            }
            canNavigate = evaluateSpeech.evaluate_valid(audioFileURL: audioURL, textFileURL: textURL, minAudioDuration: minAudioDuration)
        }
    }
    
    func startThinkingTimer() {
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if thinkingTimeLeft > 0 && thinkingTimerActive {
                thinkingTimeLeft -= 1
            } else if thinkingTimeLeft == 0 {
                timer.invalidate()
            }
        }
    }
}

