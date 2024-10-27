import SwiftUI
import MultipeerConnectivity

// Multipeer Connectivityの管理クラス
class MultipeerSession: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let serviceType = "example-room"  // 任意のサービスタイプ
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedData: String = ""
    
    override init() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    func startHosting() {
        advertiser.startAdvertisingPeer()
    }
    
    func joinSession() {
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    // 接続状態が変わった際に呼ばれるデリゲートメソッド
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }
    
    // データを受信した際に呼ばれるデリゲートメソッド
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.receivedData = String(data: data, encoding: .utf8) ?? ""
        }
    }
    
    // 招待を受信した際のハンドラー
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
    
    // ピアを発見した際のハンドラー
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// メインのビュー
struct TwoPlayerView: View {
    @StateObject private var multipeerSession = MultipeerSession()
    @State private var isHost = false
    @State private var roomCode = ""
    @State private var enteredRoomCode = ""
    @State private var joinError: String?  // エラーメッセージを表示するため
    @State private var currentPage = 1
    @State private var participants: [String] = []
    @State private var themes: [String] = []
    @State private var newTheme = ""
    @State private var generatedThemes: [String] = []
    @State private var selectedTheme: String?
    @State private var isRecording = false
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    @State private var speechContent = ""
    @State private var evaluationResult: EvaluationResult?
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var evaluateSpeech = EvaluateSpeech()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding()
            
            switch currentPage {
            case 1:
                setupOrJoinPage
            case 2:
                waitingForParticipantPage
            case 3:
                themeInputPage
            case 4:
                themeSelectionPage
            case 5:
                recordingPage
            case 6:
                resultPage
            default:
                EmptyView()
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
            multipeerSession.stop() // Viewが閉じたときにセッションを停止
        }
    }
    
    // ホスト設定またはルーム参加ページ
    var setupOrJoinPage: some View {
        VStack(spacing: 20) {
            Text("Connected Peers: \(multipeerSession.connectedPeers.map(\.displayName).joined(separator: ", "))")
                .padding()
            
            if isHost {
                TextField("Set 4-digit Room Code", text: $roomCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                
                Button(action: {
                    if roomCode.count == 4 {
                        multipeerSession.startHosting()
                        currentPage = 2 // 待機画面に進む
                    } else {
                        joinError = "Please enter a valid 4-digit code."
                    }
                }) {
                    Text("Create Room")
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                TextField("Enter Room Code", text: $enteredRoomCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                
                Button(action: {
                    if enteredRoomCode == roomCode {
                        multipeerSession.joinSession()
                        currentPage = 3 // 参加後、テーマ入力画面に進む
                    } else {
                        joinError = "Invalid Room Code."
                    }
                }) {
                    Text("Join Room")
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if let error = joinError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                isHost.toggle()
                roomCode = ""
                enteredRoomCode = ""
                joinError = nil
            }) {
                Text(isHost ? "Switch to Join" : "Switch to Host")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }
    
    // 待機画面
    var waitingForParticipantPage: some View {
        VStack(spacing: 20) {
            Text("ホストサーバー")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("ルームコード: \(roomCode)")
                .font(.title2)
                .padding()
            
            Text("Connected Peers: \(multipeerSession.connectedPeers.map(\.displayName).joined(separator: ", "))")
                .padding()
            
            if multipeerSession.connectedPeers.isEmpty {
                Text("参加者を待機中...")
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    currentPage = 3 // 参加者が接続され、準備ができたらテーマ入力ページへ
                }) {
                    Text("Ready")
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    var themeInputPage: some View {
        VStack(spacing: 20) {
            Text("Enter Themes")
                .font(.title)
            
            Text("Time Remaining: \(timeRemaining)")
            
            ForEach(themes, id: \.self) { theme in
                Text(theme)
            }
            
            HStack {
                TextField("New Theme", text: $newTheme)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addTheme) {
                    Text("Add")
                        .frame(width: 60, height: 30)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
            .padding()
        }
    }
    
    var themeSelectionPage: some View {
        VStack(spacing: 20) {
            Text("Select Theme")
                .font(.title)
            
            Text("Time Remaining: \(timeRemaining)")
            
            ForEach(generatedThemes, id: \.self) { theme in
                Button(action: {
                    selectedTheme = theme
                }) {
                    Text(theme)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTheme == theme ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    var recordingPage: some View {
        VStack(spacing: 20) {
            Text(selectedTheme ?? "No theme selected")
                .font(.title)
            
            Text("Time Remaining: \(timeRemaining)")
            
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(isRecording ? .red : .blue)
            }
        }
    }
    
    var resultPage: some View {
        VStack(spacing: 20) {
            Text("Results")
                .font(.title)
            
            if let result = evaluationResult {
                Text("Winner: \(result.winner)")
                Text("Your Score: \(result.yourScore)")
                Text("Opponent's Score: \(result.opponentScore)")
                
                Text("Your Evaluation:")
                Text("Pronunciation: \(result.pronunciation)")
                Text("Fluency: \(result.fluency)")
                
                Text("Speech Summary:")
                Text(result.speechSummary)
            } else {
                Text("Evaluation not available")
            }
        }
    }
    
    func addTheme() {
        if !newTheme.isEmpty {
            themes.append(newTheme)
            newTheme = ""
        }
    }
    
    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            speechManager.startRecording()
        } else {
            speechManager.stopRecording()
            speechManager.transcribeAudioFile { success in
                if success {
                    evaluateSpeechContent()
                }
            }
        }
    }
    
    func evaluateSpeechContent() {
        guard let audioFileURL = speechManager.audioFileURL,
              let textFileURL = speechManager.textFileURL else {
            return
        }
        
        evaluateSpeech.evaluatePronunciationAndProcess(audioFileURL: audioFileURL, textFileURL: textFileURL) { result in
            switch result {
            case .success(let processedData):
                DispatchQueue.main.async {
                    self.evaluationResult = EvaluationResult(
                        winner: "TBD",
                        yourScore: Int(processedData.speechacePronunciation + processedData.speechaceFluency),
                        opponentScore: 0,
                        pronunciation: processedData.speechacePronunciation,
                        fluency: processedData.speechaceFluency,
                        speechSummary: "Summary to be generated"
                    )
                    self.currentPage = 6
                }
            case .failure(let error):
                print("Evaluation failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                moveToNextPage()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func moveToNextPage() {
        currentPage += 1
        if currentPage == 3 || currentPage == 4 {
            timeRemaining = 30
        } else if currentPage == 5 {
            timeRemaining = 60
        }
        startTimer()
    }
}

// EvaluationResult構造体
struct EvaluationResult {
    let winner: String
    let yourScore: Int
    let opponentScore: Int
    let pronunciation: Double
    let fluency: Double
    let speechSummary: String
}

struct TwoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        TwoPlayerView()
    }
}

