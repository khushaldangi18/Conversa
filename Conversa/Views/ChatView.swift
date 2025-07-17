import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    let chatId: String
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var otherUser: User?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                // Profile Image
                if let photoURL = otherUser?.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(otherUser?.username.isEmpty == false ? "\(otherUser?.username ?? "")" : otherUser?.fullName ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // Messages List
            if isLoading {
                Spacer()
                ProgressView("Loading messages...")
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == Auth.auth().currentUser?.uid
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Message Input
            HStack(spacing: 6) {
                Button {
                    // Attachment action
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    
                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOtherUser()
            setupMessageListener()
        }
    }
    
    private func loadOtherUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("chats").document(chatId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                let participants = data["participants"] as? [String] ?? []
                let otherUserId = participants.first { $0 != currentUserId } ?? ""
                
                Firestore.firestore().collection("users").document(otherUserId).getDocument { userSnapshot, error in
                    if let userData = userSnapshot?.data() {
                        self.otherUser = User(
                            uid: otherUserId,
                            email: userData["email"] as? String ?? "",
                            fullName: userData["fullName"] as? String ?? "",
                            username: userData["username"] as? String ?? "",
                            photoURL: userData["photoURL"] as? String ?? ""
                        )
                    }
                }
            }
        }
    }
    
    private func setupMessageListener() {
        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading messages: \(error)")
                    return
                }
                
                self.messages = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Message(
                        id: document.documentID,
                        text: data["text"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        type: data["type"] as? String ?? "text"
                    )
                } ?? []
                
                self.isLoading = false
            }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let messageData: [String: Any] = [
            "text": messageText,
            "senderId": currentUserId,
            "timestamp": Timestamp(),
            "type": "text"
        ]
        
        // Add message to subcollection
        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: messageData) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                    return
                }
                
                // Update chat's last message
                let lastMessageData: [String: Any] = [
                    "lastMessage": [
                        "text": self.messageText,
                        "senderId": currentUserId,
                        "timestamp": Timestamp(),
                        "type": "text"
                    ],
                    "lastMessageRead": [
                        currentUserId: true,
                        self.otherUser?.uid ?? "": false
                    ]
                ]
                
                Firestore.firestore()
                    .collection("chats")
                    .document(self.chatId)
                    .updateData(lastMessageData)
            }
        
        messageText = ""
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct Message: Identifiable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
    let type: String
}

#Preview {
    ChatView(chatId: "sample-chat-id")
}
