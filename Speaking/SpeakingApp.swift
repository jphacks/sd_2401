//
//  SpeakingApp.swift
//  Speaking
//
//  Created by 松田陵佑 on 2024/10/20.
//

import SwiftUI

@main
struct MyApp: App {
    // @StateObject private var speechManager = SpeechManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
              // .environmentObject(speechManager) // Inject into the environment
        }
    }
}
