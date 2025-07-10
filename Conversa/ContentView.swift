//
//  ContentView.swift
//  Chatora
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var showingLoginView = false

    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading screen while determining auth state
                VStack(spacing: 30) {
                    // App Logo with pulse animation
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(authManager.isLoading ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: authManager.isLoading)

                    // App Name
                    Text("Conversa")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Loading indicator with text
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)

                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    print("📱 ContentView: Loading screen appeared")
                }
            } else {
                // Main content when auth state is determined
                NavigationView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "message.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Welcome to Conversa!")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            if let user = authManager.user {
                                Text("Hello, \(user.fullName.isEmpty ? user.email : user.fullName)!")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 40)

                        Spacer()

                        // Main Content Area (Placeholder for chat features)
                        VStack(spacing: 15) {
                            Text("Your chats will appear here")
                                .font(.title2)
                                .foregroundColor(.secondary)

                            Text("Start connecting with friends!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Sign Out Button
                        Button(action: {
                            signOut()
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                    .navigationTitle("Conversa")
                    .navigationBarTitleDisplayMode(.inline)
                }
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
            print("📱 ContentView: Auth state changed to \(isAuthenticated), loading: \(authManager.isLoading)")
            if !isAuthenticated && !authManager.isLoading {
                print("📱 ContentView: Showing login view (auth changed)")
                showingLoginView = true
            } else if isAuthenticated {
                print("📱 ContentView: Hiding login view (authenticated)")
                showingLoginView = false
            }
        }
    }

    private func signOut() {
        do {
            try authManager.signOut()
            showingLoginView = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
