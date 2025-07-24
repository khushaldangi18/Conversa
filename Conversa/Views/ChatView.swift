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
    @State private var chatOpenedAt: Date = Date()
    @State private var seenStatusTimer: Timer?
    @State private var isViewActive = false
    @Environment(\.dismiss) private var dismiss
    
    private func confirmBlockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let otherUser = otherUser else { return }
        
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
                // Post notification to refresh chat list
                NotificationCenter.default.post(name: NSNotification.Name("UserBlocked"), object: nil)
                
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
                    
                    if onlineStatus == "online" {
                        Text("Online")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
//                    } else if let lastSeen = lastSeen {
//                        Text("Last seen \(formatLastSeen(lastSeen))")
//                            .font(.system(size: 12))
//                            .foregroundColor(.gray)
                    } else {
                        Text("Offline")
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
                                    isCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                                    onImageTap: { imageURL in
                                        previewImageURL = imageURL
                                        showingImagePreview = true
                                    },
                                    onLongPress: { message in
                                        messageToDelete = message
                                        showingDeleteAlert = true
                                    },
                                    otherUserId: otherUser?.uid
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
            isViewActive = true
            loadOtherUser()
            setupMessageListener()
            startSeenStatusTimer()
            if let currentUserId = Auth.auth().currentUser?.uid {
                PresenceManager.shared.setupPresence(for: currentUserId)
            }
        }
        .onDisappear {
            isViewActive = false
            stopSeenStatusTimer()
            removeStatusObserver()
            // Clean up presence system
            PresenceManager.shared.cleanupPresence()
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
                        // Start observing status after user is loaded
                        self.observeUserStatus()
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
                        return nil
                    }
                    
                    let isDeleted = data["deleted"] as? Bool ?? false
                    let messageText = isDeleted ? "This message was deleted" : (data["text"] as? String ?? "")
                    let readBy = data["readBy"] as? [String] ?? []
                    
                    return Message(
                        id: document.documentID,
                        text: messageText,
                        senderId: data["senderId"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        type: data["type"] as? String ?? "text",
                        deleted: isDeleted,
                        readBy: readBy
                    )
                } ?? []
                
                self.isLoading = false
                
                // Mark messages as read when they appear
                self.markMessagesAsRead()
            }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let messageData: [String: Any] = [
            "text": trimmedMessage,
            "senderId": currentUserId,
            "timestamp": Timestamp(),
            "type": "text",
            "readBy": [currentUserId] // Sender has read their own message
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
                        "text": trimmedMessage,
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
                    .updateData(lastMessageData) { error in
                        if let error = error {
                            print("Error updating last message: \(error)")
                        }
                    }
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
                } else {
                    self.updateLastMessageAfterDeletion(deletedMessageId: message.id)
                }
            }
        } else {
            // Delete for me only - add to deletedFor array
            messageRef.updateData([
                "deletedFor": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    print("Error deleting message for me: \(error)")
                } else {
                    self.updateLastMessageAfterDeletion(deletedMessageId: message.id)
                }
            }
        }
    }

    private func updateLastMessageAfterDeletion(deletedMessageId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Get the most recent message that's not deleted for current user
        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting messages for last message update: \(error)")
                    return
                }
                
                // Find the most recent visible message
                let visibleMessage = snapshot?.documents.first { document in
                    let data = document.data()
                    let deletedFor = data["deletedFor"] as? [String] ?? []
                    let isDeleted = data["deleted"] as? Bool ?? false
                    
                    // Skip if deleted for current user or deleted for everyone
                    return !deletedFor.contains(currentUserId) && !isDeleted
                }
                
                let lastMessageData: [String: Any]
                
                if let visibleMessage = visibleMessage {
                    let data = visibleMessage.data()
                    let messageType = data["type"] as? String ?? "text"
                    let messageText = messageType == "image" ? "📷 Photo" : (data["text"] as? String ?? "")
                    
                    lastMessageData = [
                        "lastMessage": [
                            "text": messageText,
                            "senderId": data["senderId"] as? String ?? "",
                            "timestamp": data["timestamp"] as? Timestamp ?? Timestamp(),
                            "type": messageType
                        ]
                    ]
                } else {
                    // No visible messages left
                    lastMessageData = [
                        "lastMessage": [
                            "text": "",
                            "senderId": "",
                            "timestamp": Timestamp(),
                            "type": "text"
                        ]
                    ]
                }
                
                // Update the chat document
                Firestore.firestore()
                    .collection("chats")
                    .document(self.chatId)
                    .updateData(lastMessageData) { error in
                        if let error = error {
                            print("Error updating last message after deletion: \(error)")
                        }
                    }
            }
    }
    
    private func markMessagesAsRead() {
        guard isViewActive,
              let currentUserId = Auth.auth().currentUser?.uid else { 
            print("View not active or no user - skipping mark as read")
            return 
        }
        
        print("Timer fired - marking messages as read")
        
        // Mark all unread messages from other user as read
        let unreadMessages = messages.filter { message in
            message.senderId != currentUserId && 
            !message.readBy.contains(currentUserId)
        }
        
        guard !unreadMessages.isEmpty else { 
            print("No unread messages to mark")
            return 
        }
        
        let batch = Firestore.firestore().batch()
        
        for message in unreadMessages {
            let messageRef = Firestore.firestore()
                .collection("chats")
                .document(chatId)
                .collection("messages")
                .document(message.id)
            
            batch.updateData([
                "readBy": FieldValue.arrayUnion([currentUserId])
            ], forDocument: messageRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking messages as read: \(error)")
            } else {
                print("Successfully marked \(unreadMessages.count) messages as read")
            }
        }
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
        guard let otherUser = otherUser else { return }
        
        if let handle = statusObserverHandle {
            PresenceManager.shared.removeObserver(for: otherUser.uid, handle: handle)
            statusObserverHandle = nil
        }
    }
    private func startSeenStatusTimer() {
        stopSeenStatusTimer() // Stop any existing timer first
        seenStatusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if self.isViewActive {
                self.markMessagesAsRead()
            }
        }
    }
    
    private func stopSeenStatusTimer() {
        seenStatusTimer?.invalidate()
        seenStatusTimer = nil
        print("Seen status timer stopped")
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let onImageTap: (String) -> Void
    let onLongPress: (Message) -> Void
    let otherUserId: String? // Add this parameter
    
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
                
                HStack(spacing: 4) {
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    // Read receipt indicator for sent messages
                    if isCurrentUser {
                        if let otherUserId = otherUserId, message.readBy.contains(otherUserId) {
                            Image(systemName: "checkmark.circle.fill") // ● Blue filled
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "checkmark.circle")      // ○ Gray empty
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                }
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
    let readBy: [String] // Add this field
    
    init(id: String, text: String, senderId: String, timestamp: Date, type: String, deleted: Bool = false, readBy: [String] = []) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.timestamp = timestamp
        self.type = type
        self.deleted = deleted
        self.readBy = readBy
    }
}

#Preview {
    ChatView(chatId: "sample-chat-id")
}
 

