//
//  ChatoraApp.swift
//  Chatora
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI
import Firebase


@main
struct ChatoraApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
