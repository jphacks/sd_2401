//
//  SpeechAppApp.swift
//  SpeechApp
//
//  Created by 松田陵佑 on 2024/10/20.
//

import SwiftUI

@main
struct SpeechAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
