//
//  ContentView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            MainMessageView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .onAppear {
            // Check authentication state
            if FirebaseManager.shared.auth.currentUser == nil {
                appState.userIsLoggedIn = false
            }
        }
        // Prevent going back to login screen with gesture
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    ContentView()
}
