//
//  ProfileView.swift
//  Conversa
//
//  Created by FCP27 on 11/07/25.
//

import SwiftUI

struct ChatUser{
    let uid, email, profileImageUrl: String
}

class ProfileViewModel: ObservableObject {
    @Published var chatUser: ChatUser?

    init(){
        fetchCurrentUser()
    }
    
    private func fetchCurrentUser(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument{
            snapshot, error in
            if let error = error {
                print("Failed to fetch current user")
                return
            }
            guard let data = snapshot?.data() else {return}
//            print(data)
            
            let uid = data["uid"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
            self.chatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImageUrl)
        }
    }
}


struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showingSignOutAlert = false
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToLogin = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile image and email section
                        VStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.blue)
                                .padding(.top, 20)

                            Text(vm.chatUser?.email ?? "Loading...")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding()
                        
                        // Profile settings section
                        VStack(spacing: 0) {
                            ProfileSettingRow(icon: "person.fill", title: "Edit Profile", color: .blue)
                            ProfileSettingRow(icon: "bell.fill", title: "Notifications", color: .orange)
                            ProfileSettingRow(icon: "lock.fill", title: "Privacy", color: .green)
                            ProfileSettingRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .purple)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
                Spacer() // Push content up and sign out button to bottom
                
                // Sign out button at bottom
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                        Text("Sign Out")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .alert(isPresented: $showingSignOutAlert) {
                    Alert(
                        title: Text("Sign Out"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .destructive(Text("Sign Out")) {
                            signOut()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $navigateToLogin) {
                AuthView()
            }
        }
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
            print("Successfully signed out")
            navigateToLogin = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


struct ProfileSettingRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color(.systemBackground))
        
        Divider()
            .padding(.leading, 50)
    }
}

#Preview {
    ProfileView()
}
