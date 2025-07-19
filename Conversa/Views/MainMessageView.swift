
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct MainMessageView: View {
    @State private var showingNewChat = false
    @State private var chats: [ChatItem] = []  // Array to store all user's chats
    @State private var isLoading = true        // Loading state for initial chat fetch
    @State private var currentUser: User?      // Current logged-in user data
    @State private var selectedChatId: String? // ID of chat selected for opening
    @State private var navigateToChat = false  // Navigation trigger for ChatView
    @State private var showingDeleteAlert = false
    @State private var chatToDelete: ChatItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                HStack {
                    Text("Conversa")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Chat List Display Logic
                if isLoading {
                    // Show loading spinner while fetching chats
                    Spacer()
                    ProgressView("Loading chats...")
                    Spacer()
                } else if chats.isEmpty {
                    // Show empty state when no chats exist
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No conversations yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the + button to start a new chat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Display list of chats
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(chats, id: \.id) { chat in
                                ChatRowView(chat: chat, currentUserId: currentUser?.uid ?? "")
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Chat Opening Flow:
                                        // 1. Store the selected chat ID
                                        selectedChatId = chat.id
                                        print("Opening chat with ID: \(chat.id), Other User ID: \(chat.otherUserId)")
                                        // 2. Trigger navigation to ChatView
                                        navigateToChat = true
                                    }
                                    .onLongPressGesture {
                                        // Long press shows delete confirmation
                                        chatToDelete = chat
                                        showingDeleteAlert = true
                                    }
                                Divider()
                                    .padding(.leading, 70)
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                }
            }
            // Floating action button for new chat
            .overlay(
                Button {
                    showingNewChat = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
        }
        // Sheet for creating new chat
        .sheet(isPresented: $showingNewChat) {
            NewChatView { chatId in
                // Callback when new chat is created - opens the new chat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedChatId = chatId
                    navigateToChat = true
                }
            }
        }
        // Full screen cover for chat view
        .fullScreenCover(isPresented: $navigateToChat, onDismiss: {
            // Reset navigation state when chat is closed
            selectedChatId = nil
            navigateToChat = false
        }) {
            // Only show ChatView if we have a valid chat ID
            if let chatId = selectedChatId {
                ChatView(chatId: chatId)
            }
        }
        .onAppear {
            // Initialize data when view appears
            loadCurrentUser()      // Load current user data
            setupRealtimeListener() // Start listening for chat updates
        }
        // Delete confirmation alert
        .alert("Delete Chat", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                chatToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    deleteChat(chat)
                }
                chatToDelete = nil
            }
        } message: {
            if let chat = chatToDelete {
                Text("Are you sure you want to delete this chat? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Data Loading Functions
    
    private func loadCurrentUser() {
        // Get current user's UID from Firebase Auth
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Fetch user data from Firestore
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    // Update currentUser on main thread
                    self.currentUser = User(
                        uid: uid,
                        email: data["email"] as? String ?? "",
                        fullName: data["fullName"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        photoURL: data["photoURL"] as? String ?? ""
                    )
                    print("Current user loaded: \(self.currentUser?.username ?? "Unknown")")
                }
            }
        }
    }
    
    private func setupRealtimeListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // STEP 1: Get current user's blocked users list
        Firestore.firestore().collection("users").document(currentUserId).getDocument { snapshot, error in
            let blockedUsers = snapshot?.data()?["blockedUsers"] as? [String] ?? []
            let blockedBy = snapshot?.data()?["blockedBy"] as? [String] ?? []
            
            // STEP 2: Set up real-time listener for chats
            // This listens for any changes to chats where current user is a participant
            Firestore.firestore().collection("chats")
                .whereField("participants", arrayContains: currentUserId)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error loading chats: \(error)")
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.isLoading = false
                        return
                    }
                    
                    var newChats: [ChatItem] = []
                    
                    // STEP 3: Process each chat document
                    for document in documents {
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        // Find the other user (not current user)
                        let otherUserId = participants.first { $0 != currentUserId } ?? ""
                        
                        // STEP 4: Filter out blocked users
                        if blockedUsers.contains(otherUserId) || blockedBy.contains(otherUserId) {
                            continue // Skip this chat
                        }
                        
                        // STEP 5: Extract last message data
                        let lastMessage = data["lastMessage"] as? [String: Any] ?? [:]
                        let lastMessageText = lastMessage["text"] as? String ?? ""
                        let lastMessageTimestamp = lastMessage["timestamp"] as? Timestamp ?? Timestamp()
                        let lastMessageSenderId = lastMessage["senderId"] as? String ?? ""
                        
                        // STEP 6: Check if message is unread
                        let lastMessageRead = data["lastMessageRead"] as? [String: Bool] ?? [:]
                        let isUnread = !(lastMessageRead[currentUserId] ?? true)
                        
                        // STEP 7: Create ChatItem object
                        let chatItem = ChatItem(
                            id: document.documentID,
                            otherUserId: otherUserId,
                            lastMessage: lastMessageText,
                            lastMessageTime: lastMessageTimestamp.dateValue(),
                            lastMessageSenderId: lastMessageSenderId,
                            isUnread: isUnread
                        )
                        
                        newChats.append(chatItem)
                    }
                    
                    // STEP 8: Sort chats by most recent message and update UI
                    DispatchQueue.main.async {
                        self.chats = newChats.sorted { $0.lastMessageTime > $1.lastMessageTime }
                        self.isLoading = false
                        print("Loaded \(self.chats.count) chats")
                    }
                }
        }
    }
    
    private func deleteChat(_ chat: ChatItem) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let batch = Firestore.firestore().batch()
        
        // Delete the chat document
        let chatRef = Firestore.firestore().collection("chats").document(chat.id)
        batch.deleteDocument(chatRef)
        
        // Delete all messages in the chat subcollection
        Firestore.firestore()
            .collection("chats")
            .document(chat.id)
            .collection("messages")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting messages to delete: \(error)")
                    return
                }
                
                let messageBatch = Firestore.firestore().batch()
                
                snapshot?.documents.forEach { document in
                    messageBatch.deleteDocument(document.reference)
                }
                
                // Commit message deletions first
                messageBatch.commit { error in
                    if let error = error {
                        print("Error deleting messages: \(error)")
                        return
                    }
                    
                    // Then delete the chat document
                    batch.commit { error in
                        if let error = error {
                            print("Error deleting chat: \(error)")
                        } else {
                            // Remove from local array for immediate UI update
                            DispatchQueue.main.async {
                                self.chats.removeAll { $0.id == chat.id }
                            }
                        }
                    }
                }
            }
    }
}

struct ChatRowView: View {
    let chat: ChatItem
    let currentUserId: String
    @State private var otherUser: User?
    @State private var onlineStatus: String = "offline"
    @State private var lastSeen: Date?
    @State private var statusObserverHandle: DatabaseHandle?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image with status indicator
            ZStack(alignment: .bottomTrailing) {
                if let photoURL = otherUser?.photoURL, let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                }
                
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.username.isEmpty == false ? "\(otherUser?.username ?? "")" : otherUser?.fullName ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(chat.lastMessageTime))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if onlineStatus == "online" {
                        Text("Online")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else if let lastSeen = lastSeen {
                        Text("Last seen \(formatLastSeen(lastSeen))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
//                    if chat.isUnread && chat.lastMessageSenderId != currentUserId {
//                        Circle()
//                            .fill(Color.green)
//                            .frame(width: 8, height: 8)
//                    }
                }
                
                Text(chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(chat.lastMessage.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            loadOtherUser()
            // observeUserStatus()  // Comment this out
        }
        .onDisappear {
            // removeStatusObserver()  // Comment this out
        }
    }
    
    private func loadOtherUser() {
        UserCacheManager.shared.getUser(uid: chat.otherUserId) { user in
            DispatchQueue.main.async {
                self.otherUser = user
            }
        }
    }
    
    private func observeUserStatus() {
        // Only observe status for visible rows
        guard otherUser != nil else { return }
        
        statusObserverHandle = PresenceManager.shared.observeUserStatus(for: chat.otherUserId) { status, lastSeen in
            DispatchQueue.main.async {
                self.onlineStatus = status
                self.lastSeen = lastSeen
            }
        }
    }
    
    private func removeStatusObserver() {
        if let handle = statusObserverHandle {
            PresenceManager.shared.removeObserver(for: chat.otherUserId, handle: handle)
        }
    }
    
    private func formatLastSeen(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct ChatItem {
    let id: String
    let otherUserId: String
    let lastMessage: String
    let lastMessageTime: Date
    let lastMessageSenderId: String
    let isUnread: Bool
}

struct User {
    let uid: String
    let email: String
    let fullName: String
    let username: String
    let photoURL: String
}

#Preview {
    MainMessageView()
}
