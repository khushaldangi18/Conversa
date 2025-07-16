import SwiftUI
import Firebase
import FirebaseFirestore

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var users = [ChatUser]()
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
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
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // User list
                    List(users, id: \.uid) { user in
                        Button {
                            createChat(with: user)
                        } label: {
                            HStack {
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
                                    Text(user.email)
                                        .font(.system(size: 16, weight: .bold))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "message.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.primary)
                    }
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
        
        FirebaseManager.shared.firestore.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: searchText.lowercased())
            .whereField("username", isLessThanOrEqualTo: searchText.lowercased() + "\u{f8ff}")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to fetch users: \(error.localizedDescription)"
                    return
                }
                
                users = snapshot?.documents
                    .compactMap { document -> ChatUser? in
                        let data = document.data()
                        let uid = document.documentID
                        
                        // Skip current user
                        if uid == currentUser.uid {
                            return nil
                        }
                        
                        let email = data["email"] as? String ?? ""
                        let profileImageUrl = data["photoURL"] as? String ?? ""
                        let username = data["username"] as? String ?? ""
                        
                        return ChatUser(uid: uid, email: email, username: username, profileImageUrl: profileImageUrl)
                    } ?? []
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
                    print("Chat already exists with ID: \(existingChat.documentID)")
                    dismiss()
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
                    
                    // Update Realtime Database for quick access
                    let rtdbRef = Database.database().reference()
                    rtdbRef.child("active_chats").child(currentUser.uid).child(chatRef.documentID).setValue(ServerValue.timestamp())
                    rtdbRef.child("active_chats").child(user.uid).child(chatRef.documentID).setValue(ServerValue.timestamp())
                    
                    dismiss()
                }
            }
    }
}

#Preview {
    NewChatView()
}
