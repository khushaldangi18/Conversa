import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct MainMessageView: View {
    @State private var showingNewChat = false
    @State private var chats: [ChatItem] = []
    @State private var isLoading = true
    @State private var currentUser: User?
    @State private var showingDeleteAlert = false
    @State private var chatToDelete: ChatItem?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    Spacer()
                    ProgressView("Loading chats...")
                    Spacer()
                } else if chats.isEmpty {
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
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(chats, id: \.id) { chat in
                                NavigationLink(value: chat.id) {
                                    ChatRowView(chat: chat, currentUserId: currentUser?.uid ?? "")
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        print("Opening chat with ID: \(chat.id), Other User ID: \(chat.otherUserId)")
                                    }
                                )
                                .onLongPressGesture {
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
            .navigationDestination(for: String.self) { chatId in
                ChatView(chatId: chatId)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .sheet(isPresented: $showingNewChat) {
            NewChatView { chatId in
                navigationPath.append(chatId)
            }
        }
        .onAppear {
            loadCurrentUser()
            setupRealtimeListener()
            setupNotificationObserver()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("UserBlocked"), object: nil)
        }
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
    
    private func loadCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.currentUser = User(
                    uid: uid,
                    email: data["email"] as? String ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    photoURL: data["photoURL"] as? String ?? ""
                )
            }
        }
    }
    
    private func setupRealtimeListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Set up real-time listener for chats
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
                
                // Get current user's blocked list every time chats update
                Firestore.firestore().collection("users").document(currentUserId).getDocument { userSnapshot, userError in
                    let blockedUsers = userSnapshot?.data()?["blockedUsers"] as? [String] ?? []
                    let blockedBy = userSnapshot?.data()?["blockedBy"] as? [String] ?? []
                    
                    var newChats: [ChatItem] = []
                    
                    for document in documents {
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        let otherUserId = participants.first { $0 != currentUserId } ?? ""
                        
                        // Filter out blocked users
                        if blockedUsers.contains(otherUserId) || blockedBy.contains(otherUserId) {
                            print("Filtering out blocked user: \(otherUserId)")
                            continue
                        }
                        
                        let lastMessage = data["lastMessage"] as? [String: Any] ?? [:]
                        let lastMessageText = lastMessage["text"] as? String ?? ""
                        let lastMessageTimestamp = lastMessage["timestamp"] as? Timestamp ?? Timestamp()
                        let lastMessageSenderId = lastMessage["senderId"] as? String ?? ""
                        
                        let lastMessageRead = data["lastMessageRead"] as? [String: Bool] ?? [:]
                        let isUnread = !(lastMessageRead[currentUserId] ?? true)
                        
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
                    
                    DispatchQueue.main.async {
                        self.chats = newChats.sorted { $0.lastMessageTime > $1.lastMessageTime }
                        self.isLoading = false
                        print("Loaded \(self.chats.count) chats (blocked users filtered)")
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
    
    private func refreshChats() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Get current user's blocked list
        Firestore.firestore().collection("users").document(currentUserId).getDocument { userSnapshot, userError in
            let blockedUsers = userSnapshot?.data()?["blockedUsers"] as? [String] ?? []
            let blockedBy = userSnapshot?.data()?["blockedBy"] as? [String] ?? []
            
            // Filter existing chats
            let filteredChats = self.chats.filter { chat in
                let shouldKeep = !blockedUsers.contains(chat.otherUserId) && !blockedBy.contains(chat.otherUserId)
                if !shouldKeep {
                    print("Removing blocked user chat: \(chat.otherUserId)")
                }
                return shouldKeep
            }
            
            DispatchQueue.main.async {
                self.chats = filteredChats
                print("Refreshed chats: \(self.chats.count) remaining")
            }
        }
    }
}

extension MainMessageView {
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserBlocked"),
            object: nil,
            queue: .main
        ) { _ in
            print("Received user blocked notification - refreshing chats")
            refreshChats()
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
                    
                    if chat.isUnread && chat.lastMessageSenderId != currentUserId {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
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
