import SwiftUI
import Firebase
import FirebaseFirestore

struct UserProfileView: View {
    let userId: String
    @State private var user: User?
    @State private var isLoading = true
    @State private var onlineStatus = "offline"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if let user = user {
                    // Profile Image
                    if !user.photoURL.isEmpty, let url = URL(string: user.photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 8) {
                        Text(user.username.isEmpty ? user.fullName : user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if !user.username.isEmpty {
                            Text(user.fullName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(onlineStatus == "online" ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(onlineStatus == "online" ? "Online" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadUser()
        }
    }
    
    private func loadUser() {
        UserCacheManager.shared.getUser(uid: userId) { user in
            DispatchQueue.main.async {
                self.user = user
                self.isLoading = false
                if user != nil {
                    observeUserStatus()
                }
            }
        }
    }
    
    private func observeUserStatus() {
        PresenceManager.shared.observeUserStatus(for: userId) { status, _ in
            DispatchQueue.main.async {
                self.onlineStatus = status
            }
        }
    }
}
