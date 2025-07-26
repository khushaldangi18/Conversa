import SwiftUI
import Firebase
import FirebaseFirestore

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [ChatUser] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading blocked users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No blocked users")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Users you block will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(blockedUsers, id: \.uid) { user in
                            HStack {
                                // Profile Image
                                if let url = URL(string: user.profileImageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(user.username.isEmpty ? user.email : "@\(user.username)")
                                        .font(.system(size: 16, weight: .semibold))
                                    if !user.username.isEmpty {
                                        Text(user.email)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("Unblock") {
                                    unblockUser(user)
                                }
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadBlockedUsers()
            }
        }
    }
    
    private func loadBlockedUsers() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Failed to load blocked users: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            guard let data = snapshot?.data(),
                  let blockedUserIds = data["blockedUsers"] as? [String] else {
                isLoading = false
                return
            }
            
            if blockedUserIds.isEmpty {
                isLoading = false
                return
            }
            
            // Fetch blocked user details
            FirebaseManager.shared.firestore.collection("users")
                .whereField(FieldPath.documentID(), in: blockedUserIds)
                .getDocuments { snapshot, error in
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = "Failed to load user details: \(error.localizedDescription)"
                        return
                    }
                    
                    blockedUsers = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        return ChatUser(
                            uid: document.documentID,
                            email: data["email"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            profileImageUrl: data["photoURL"] as? String ?? "",
                            fullName: data["fullName"] as? String ?? ""
                        )
                    } ?? []
                }
            print(blockedUsers)
        }
    }
    
    private func unblockUser(_ user: ChatUser) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let batch = FirebaseManager.shared.firestore.batch()
        
        // Remove from current user's blocked list
        let currentUserRef = FirebaseManager.shared.firestore.collection("users").document(currentUserId)
        batch.updateData(["blockedUsers": FieldValue.arrayRemove([user.uid])], forDocument: currentUserRef)
        
        // Remove from other user's blockedBy list
        let otherUserRef = FirebaseManager.shared.firestore.collection("users").document(user.uid)
        batch.updateData(["blockedBy": FieldValue.arrayRemove([currentUserId])], forDocument: otherUserRef)
        
        batch.commit { error in
            if let error = error {
                errorMessage = "Failed to unblock user: \(error.localizedDescription)"
            } else {
                // Remove from local array
                blockedUsers.removeAll { $0.uid == user.uid }
            }
        }
    }
}

#Preview{
    BlockedUsersView()
}
