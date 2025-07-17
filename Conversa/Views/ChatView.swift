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
    @State private var onlineStatus: String = "offline"
    @State private var lastSeen: Date?
    @State private var statusObserverHandle: DatabaseHandle?
    @State private var showingBlockAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private func confirmBlockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let otherUser  = otherUser else { return }
        
        let batch = Firestore.firestore().batch()
        
        // Add to current user's blocked list
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        batch.updateData(["blockedUsers": FieldValue.arrayUnion([otherUser.uid])], forDocument: currentUserRef)
        
        // Add to other user's blockedBy list
        let otherUserRef = Firestore.firestore().collection("users").document(otherUser.uid)
        batch.updateData(["blockedBy": FieldValue.arrayUnion([currentUserId])], forDocument: otherUserRef)
        
        batch.commit { error in
            if let error = error {
                print("Failed to block user: \(error)")
            } else {
                // Navigate back to main view
                dismiss()
            }
        }
    }
    
    private func blockUser() {
        showingBlockAlert = true
    }

    
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
                
                // Profile Image with status indicator
                ZStack(alignment: .bottomTrailing) {
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
                    
                    // Online status indicator
                    Circle()
                        .fill(onlineStatus == "online" ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(otherUser?.username.isEmpty == false ? "\(otherUser?.username ?? "")" : otherUser?.fullName ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if onlineStatus == "online" {
                        Text("Online")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else if let lastSeen = lastSeen {
                        Text("Last seen \(formatLastSeen(lastSeen))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Block User", role: .destructive) {
                        blockUser()
                    }
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
            HStack(spacing: 12) {
                Button {
                    // Attachment action
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.green)
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                    
                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue).padding(.trailing, 6)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(40)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOtherUser()
            setupMessageListener()
            observeUserStatus()
        }
        .onDisappear {
            removeStatusObserver()
        }
        .alert("Block User", isPresented: $showingBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                confirmBlockUser()
            }
        } message: {
            Text("Are you sure you want to block \(otherUser?.username ?? "this user")? You won't receive messages from them.")
        }
    }
    
    private func loadOtherUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("chats").document(chatId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                let participants = data["participants"] as? [String] ?? []
                let otherUserId = participants.first { $0 != currentUserId } ?? ""
                
                // Use cached user data
                UserCacheManager.shared.getUser(uid: otherUserId) { user in
                    DispatchQueue.main.async {
                        self.otherUser = user
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
            .limit(toLast: 50) // Load only last 50 messages initially
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
    
    private func observeUserStatus() {
        guard let otherUser = otherUser else { return }
        
        statusObserverHandle = PresenceManager.shared.observeUserStatus(for: otherUser.uid) { status, lastSeen in
            DispatchQueue.main.async {
                self.onlineStatus = status
                self.lastSeen = lastSeen
            }
        }
    }

    private func removeStatusObserver() {
        guard let otherUser = otherUser, let handle = statusObserverHandle else { return }
        PresenceManager.shared.removeObserver(for: otherUser.uid, handle: handle)
    }

    private func formatLastSeen(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
 

