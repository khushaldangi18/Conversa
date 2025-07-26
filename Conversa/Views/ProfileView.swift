//
//  ProfileView.swift
//  Conversa
//
//  Created by FCP27 on 11/07/25.
// 

import SwiftUI

struct ChatUser {
    let uid, email, username, profileImageUrl, fullName: String
}

class ProfileViewModel: ObservableObject {
    @Published var chatUser: ChatUser?
    @Published var profileImage: UIImage?
    
    private let defaultImageUrl = "https://firebasestorage.googleapis.com/v0/b/chatora-f12b1.firebasestorage.app/o/default_image.jpg?alt=media&token=a70a47b0-5834-491a-85d4-941b156519e3"
    
    init() {
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            
            let uid = data["uid"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            let profileImageUrl = data["photoURL"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? ""

            self.chatUser = ChatUser(
                uid: uid, 
                email: email, 
                username: username, 
                profileImageUrl: profileImageUrl,
                fullName: fullName
            )
            
            self.loadProfileImage(from: profileImageUrl)
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        let imageUrl = urlString.isEmpty ? defaultImageUrl : urlString
        
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Failed to load profile image: \(error)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.profileImage = image
            }
        }.resume()
    }
}


struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showingSignOutAlert = false
    @State private var showingBlockedUsers = false
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToLogin = false
    @EnvironmentObject private var appState: AppState
    @State private var showingHelpFeedback = false
    @State private var showingChatRequests = false
    @State private var showingPrivacySettings = false
    @State private var isProfilePublic = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile image and user info section
                        VStack(spacing: 8) {
                            if let image = vm.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .shadow(radius: 6)
                            } else {
                                ProgressView()
                                    .frame(width: 120, height: 120)
                                    .scaledToFill()
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                                    .shadow(radius: 6)
                            }
                            
                            Text(vm.chatUser?.fullName ?? "")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                if let username = vm.chatUser?.username, !username.isEmpty {
                                    Text("@\(username)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("•")
                                    .foregroundColor(.black.opacity(0.5))
                                    .padding(.horizontal, 2)
                                
                                Image(systemName: "envelope")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                
                                Text(vm.chatUser?.email ?? "Loading...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        // Profile settings section
                        VStack(spacing: 0) {
                            NavigationLink(destination: EditProfileView(currentUser: vm.chatUser, profileImage: vm.profileImage) {
                                vm.fetchCurrentUser()
                            }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    Text("Edit Profile")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            
                            if !isProfilePublic {
                                Divider()
                                    .padding(.leading, 50)
                                
                                Button {
                                    showingChatRequests = true
                                } label: {
                                    HStack {
                                        Image(systemName: "person.2.badge.plus")
                                            .foregroundColor(.purple)
                                            .frame(width: 30)
                                        
                                        Text("Chat Requests")
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                }
                            }
                            
                            Divider()
                                .padding(.leading, 50)
                            
                            ProfileSettingRow(icon: "hand.raised.fill", title: "Blocked Users", color: .red) {
                                showingBlockedUsers = true
                            }
                            
                            Button {
                                showingPrivacySettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 30)
                                    
                                    Text("Privacy")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            
                            Divider()
                                .padding(.leading, 50)
                            
                            NavigationLink(destination: HelpFeedbackView()) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 30)
                                    
                                    Text("Help & Feedback")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
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
            .sheet(isPresented: $showingBlockedUsers) {
                BlockedUsersView()
            }
            .sheet(isPresented: $showingChatRequests) {
                ChatRequestsView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView(isProfilePublic: $isProfilePublic)
            }
            .fullScreenCover(isPresented: $navigateToLogin) {
                AuthView()
                    .onDisappear {
                        checkAuthState()
                    }
            }
            .onAppear {
                checkAuthState()
                loadProfileType()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .interactiveDismissDisabled(true)
    }
    
    func signOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
            print("Successfully signed out")
            
            // Update app state using our EnvironmentObject
            appState.userIsLoggedIn = false
            
            // Navigate to login
            navigateToLogin = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func checkAuthState() {
        // If user is not authenticated, navigate to login
        if FirebaseManager.shared.auth.currentUser == nil {
            navigateToLogin = true
        }
    }
    
    private func loadProfileType() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.isProfilePublic = data["isPublic"] as? Bool ?? true
                }
            }
        }
    }
    
    private func updateProfileType(isPublic: Bool) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).updateData([
            "isPublic": isPublic
        ]) { error in
            if let error = error {
                print("Failed to update profile type: \(error)")
            }
        }
    }
}


struct ProfileSettingRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
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
        }
        
        Divider()
            .padding(.leading, 50)
    }
}

#Preview {
    ProfileView()
}
