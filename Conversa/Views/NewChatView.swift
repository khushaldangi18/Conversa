import SwiftUI
import Firebase
import FirebaseFirestore

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var users = [ChatUser]()
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let onChatCreated: (String) -> Void
    
    init(onChatCreated: @escaping (String) -> Void = { _ in }) {
        self.onChatCreated = onChatCreated
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar - fixed at top
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search by username", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { _ in
                                if !searchText.isEmpty {
                                    searchUsers()
                                } else {
                                    users = []
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                users = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Content area
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if !errorMessage.isEmpty {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if users.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else if !users.isEmpty {
                    // User list
                    List(users, id: \.uid) { user in
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
                            
                            Menu {
                                Button("Start Chat") {
                                    createChat(with: user)
                                }
                                Button("Block User", role: .destructive) {
                                    blockUser(user)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .listStyle(PlainListStyle())
                } else {
                    Spacer()
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for users by username")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        users = []
        errorMessage = ""
        
        guard let currentUser = FirebaseManager.shared.auth.currentUser else {
            isLoading = false
            errorMessage = "Not logged in"
            return
        }
        
        // First get current user's blocked list
        FirebaseManager.shared.firestore.collection("users").document(currentUser.uid).getDocument { snapshot, error in
            let blockedUsers = snapshot?.data()?["blockedUsers"] as? [String] ?? []
            let blockedBy = snapshot?.data()?["blockedBy"] as? [String] ?? []
            
            // Get all users and filter locally (simpler approach)
            FirebaseManager.shared.firestore.collection("users")
                .limit(to: 100) // Limit to prevent large queries
                .getDocuments { snapshot, error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to fetch users: \(error.localizedDescription)"
                        return
                    }
                    
                    let searchTextLower = self.searchText.lowercased()
                    
                    self.users = snapshot?.documents
                        .compactMap { document -> ChatUser? in
                            let data = document.data()
                            let uid = document.documentID
                            
                            // Skip current user, blocked users, and users who blocked current user
                            if uid == currentUser.uid || 
                               blockedUsers.contains(uid) || 
                               blockedBy.contains(uid) {
                                return nil
                            }
                            
                            let email = data["email"] as? String ?? ""
                            let profileImageUrl = data["photoURL"] as? String ?? ""
                            let username = data["username"] as? String ?? ""
                            let fullName = data["fullName"] as? String ?? ""

                            // Filter by search text (username or email)
                            let matchesUsername = username.lowercased().contains(searchTextLower)
                            let matchesEmail = email.lowercased().contains(searchTextLower)

                            if matchesUsername || matchesEmail {
                                return ChatUser(uid: uid, email: email, username: username, profileImageUrl: profileImageUrl, fullName: fullName)
                            }

                            return nil
                        } ?? []
                }
        }
    }
    
    private func createChat(with user: ChatUser) {
        guard let currentUser = FirebaseManager.shared.auth.currentUser else {
            errorMessage = "Not logged in"
            return
        }
        
        // Check if chat already exists
        FirebaseManager.shared.firestore.collection("chats")
            .whereField("participants", arrayContains: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to check existing chats: \(error.localizedDescription)"
                    return
                }
                
                // Check if chat with this user already exists
                let existingChat = snapshot?.documents.first { document in
                    let participants = document.data()["participants"] as? [String] ?? []
                    return participants.contains(user.uid)
                }
                
                if let existingChat = existingChat {
                    // Chat already exists, navigate to it
                    dismiss()
                    onChatCreated(existingChat.documentID)
                    return
                }
                
                // Create new chat
                let newChatData: [String: Any] = [
                    "participants": [currentUser.uid, user.uid],
                    "createdAt": Timestamp(),
                    "lastMessage": [
                        "text": "",
                        "senderId": "",
                        "timestamp": Timestamp(),
                        "type": "text"
                    ],
                    "lastMessageRead": [
                        currentUser.uid: true,
                        user.uid: false
                    ]
                ]
                
                let chatRef = FirebaseManager.shared.firestore.collection("chats").document()
                chatRef.setData(newChatData) { error in
                    if let error = error {
                        errorMessage = "Failed to create chat: \(error.localizedDescription)"
                        return
                    }
                    
                    dismiss()
                    onChatCreated(chatRef.documentID)
                }
            }
    }
    
    private func blockUser(_ user: ChatUser) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let batch = FirebaseManager.shared.firestore.batch()
        
        // Add to current user's blocked list
        let currentUserRef = FirebaseManager.shared.firestore.collection("users").document(currentUserId)
        batch.updateData(["blockedUsers": FieldValue.arrayUnion([user.uid])], forDocument: currentUserRef)
        
        // Add to other user's blockedBy list
        let otherUserRef = FirebaseManager.shared.firestore.collection("users").document(user.uid)
        batch.updateData(["blockedBy": FieldValue.arrayUnion([currentUserId])], forDocument: otherUserRef)
        
        batch.commit { error in
            if let error = error {
                errorMessage = "Failed to block user: \(error.localizedDescription)"
            } else {
                // Remove from search results
                users.removeAll { $0.uid == user.uid }
            }
        }
    }
}

#Preview {
    NewChatView()
}
