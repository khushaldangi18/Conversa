//
//  ChatoraApp.swift
//  Chatora
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

@main
struct ChatoraApp: App {

    init() {
        FirebaseApp.configure()
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
