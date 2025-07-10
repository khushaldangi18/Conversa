//
//  ContentView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var showingLoginView = false

    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading screen while determining auth state
                LoadingView()
            } else {
                // Main content when auth state is determined
                HomeView()
            }
        }
        .fullScreenCover(isPresented: $showingLoginView) {
            LoginView()
        }
        .onChange(of: authManager.isLoading) { isLoading in
            print("📱 ContentView: Loading state changed to \(isLoading)")
            if !isLoading && !authManager.isAuthenticated {
                print("📱 ContentView: Showing login view (not authenticated)")
                showingLoginView = true
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            print("ContentView: Auth state changed to \(isAuthenticated), loading: \(authManager.isLoading)")
            if !isAuthenticated && !authManager.isLoading {
                print("ContentView: Showing login view (auth changed)")
                showingLoginView = true
            } else if isAuthenticated {
                print("ContentView: Hiding login view (authenticated)")
                showingLoginView = false
            }
        }
    }


}

#Preview {
    ContentView()
}
