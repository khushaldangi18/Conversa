import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    @State private var showingImagePreview = false
    @State private var previewImageURL: String = ""
    @State private var showingDeleteAlert = false
    @State private var messageToDelete: Message?
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
                                    isCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                                    onImageTap: { imageURL in
                                        previewImageURL = imageURL
                                        showingImagePreview = true
                                    },
                                    onLongPress: { message in
                                        messageToDelete = message
                                        showingDeleteAlert = true
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            // Message Input
            HStack(spacing: 8) {
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                }
                
                HStack {
                    TextField("Type a message..", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .padding(.leading, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                        )
                    
                    if !messageText.isEmpty || isUploadingImage {
                        Button {
                            if !messageText.isEmpty {
                                sendMessage()
                            }
                        } label: {
                            if isUploadingImage {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 6)
                            }
                        }
                        .disabled(isUploadingImage)
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
//            observeUserStatus()
        }
        .onDisappear {
//            removeStatusObserver()
        }
        .alert("Block User", isPresented: $showingBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                confirmBlockUser()
            }
        } message: {
            Text("Are you sure you want to block \(otherUser?.username ?? "this user")? You won't receive messages from them.")
        }
        .sheet(isPresented: $showingImagePicker) {
            ChatImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                sendImageMessage(image: image)
            }
        }
        .sheet(isPresented: $showingImagePreview) {
            ImagePreviewView(imageURL: previewImageURL)
        }
        .alert("Delete Message", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                messageToDelete = nil
            }
            Button("Delete for Me", role: .destructive) {
                if let message = messageToDelete {
                    deleteMessage(message, deleteForEveryone: false)
                }
                messageToDelete = nil
            }
            if messageToDelete?.senderId == Auth.auth().currentUser?.uid {
                Button("Delete for Everyone", role: .destructive) {
                    if let message = messageToDelete {
                        deleteMessage(message, deleteForEveryone: true)
                    }
                    messageToDelete = nil
                }
            }
        } message: {
            if messageToDelete?.senderId == Auth.auth().currentUser?.uid {
                Text("You can delete this message for yourself or for everyone.")
            } else {
                Text("This message will be deleted for you only.")
            }
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
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(toLast: 50)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading messages: \(error)")
                    return
                }
                
                self.messages = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    
                    // Check if message is deleted for current user
                    let deletedFor = data["deletedFor"] as? [String] ?? []
                    if deletedFor.contains(currentUserId) {
                        return nil // Don't show this message
                    }
                    
                    let isDeleted = data["deleted"] as? Bool ?? false
                    let messageText = isDeleted ? "This message was deleted" : (data["text"] as? String ?? "")
                    
                    return Message(
                        id: document.documentID,
                        text: messageText,
                        senderId: data["senderId"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        type: data["type"] as? String ?? "text",
                        deleted: isDeleted
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
    
    private func sendImageMessage(image: UIImage) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        isUploadingImage = true
        
        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
            .child("chat_images")
            .child(chatId)
            .child(filename)
        
        // Upload image
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                isUploadingImage = false
                return
            }
            
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    isUploadingImage = false
                    return
                }
                
                guard let downloadURL = url else {
                    isUploadingImage = false
                    return
                }
                
                // Send message with image URL
                let messageData: [String: Any] = [
                    "text": downloadURL.absoluteString,
                    "senderId": currentUserId,
                    "timestamp": Timestamp(),
                    "type": "image"
                ]
                
                Firestore.firestore()
                    .collection("chats")
                    .document(chatId)
                    .collection("messages")
                    .addDocument(data: messageData) { error in
                        if let error = error {
                            print("Error sending image message: \(error)")
                        } else {
                            // Update chat's last message
                            let lastMessageData: [String: Any] = [
                                "lastMessage": [
                                    "text": "📷 Photo",
                                    "senderId": currentUserId,
                                    "timestamp": Timestamp(),
                                    "type": "image"
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
                        
                        isUploadingImage = false
                        selectedImage = nil
                    }
            }
        }
    }
    
    private func deleteMessage(_ message: Message, deleteForEveryone: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let messageRef = Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .document(message.id)
        
        if deleteForEveryone && message.senderId == currentUserId {
            // Delete for everyone - mark as deleted
            messageRef.updateData([
                "deleted": true,
                "deletedAt": Timestamp(),
                "text": "This message was deleted"
            ]) { error in
                if let error = error {
                    print("Error deleting message for everyone: \(error)")
                }
            }
        } else {
            // Delete for me only - add to deletedFor array
            messageRef.updateData([
                "deletedFor": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    print("Error deleting message for me: \(error)")
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let onImageTap: (String) -> Void
    let onLongPress: (Message) -> Void
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if message.type == "image" && !message.deleted {
                    AsyncImage(url: URL(string: message.text)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(12)
                            .onTapGesture {
                                onImageTap(message.text)
                            }
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 150)
                            .overlay(
                                ProgressView()
                            )
                    }
                    .onLongPressGesture {
                        onLongPress(message)
                    }
                } else {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.deleted ? Color(.systemGray4) : (isCurrentUser ? Color.blue : Color(.systemGray5)))
                        .foregroundColor(message.deleted ? .secondary : (isCurrentUser ? .white : .primary))
                        .cornerRadius(18)
                        .italic(message.deleted)
                        .onLongPressGesture {
                            onLongPress(message)
                        }
                }
                
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
    let deleted: Bool
    
    init(id: String, text: String, senderId: String, timestamp: Date, type: String, deleted: Bool = false) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.timestamp = timestamp
        self.type = type
        self.deleted = deleted
    }
}

#Preview {
    ChatView(chatId: "sample-chat-id")
}
 

