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
                                    Text(user.username.isEmpty ? user.email : "@\(user.username)")
                                        .font(.system(size: 16, weight: .bold))
                                    if !user.username.isEmpty {
                                        Text(user.email)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "message.circle.fill")
                                        .font(.system(size: 28))
                                    .foregroundColor(.green)
                                    .frame(width: 35, height: 35)
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
}

#Preview {
    NewChatView()
}
