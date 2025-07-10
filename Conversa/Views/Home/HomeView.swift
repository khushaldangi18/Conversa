//
//  HomeView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Welcome Header
                WelcomeHeaderView(
                    userName: authManager.user?.fullName,
                    userEmail: authManager.user?.email
                )
                
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
                
                // Action Buttons Section
                VStack(spacing: 15) {
                    // Future: Add New Chat Button
                    Button(action: {
                        // TODO: Implement new chat functionality
                        print("New chat button tapped")
                    }) {
                        HStack {
                            Image(systemName: "plus.message")
                            Text("Start New Chat")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    // Sign Out Button
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Conversa")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() {
        do {
            try authManager.signOut()
            print("📱 HomeView: User signed out successfully")
        } catch {
            print("📱 HomeView: Error signing out: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HomeView()
}
