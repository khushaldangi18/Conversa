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
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var chatUsers: [String: User] = [:] // Cache for user data
    
    private var filteredChats: [ChatItem] {
        if searchText.isEmpty {
            return chats
        } else {
            return chats.filter { chat in
                let searchTextLower = searchText.lowercased()
                
                // Search in last message
                let messageMatch = chat.lastMessage.localizedCaseInsensitiveContains(searchText)
                
                // Search in user's name and username
                if let user = chatUsers[chat.otherUserId] {
                    let nameMatch = user.fullName.lowercased().contains(searchTextLower)
                    let usernameMatch = user.username.lowercased().contains(searchTextLower)
                    return messageMatch || nameMatch || usernameMatch
                }
                
                return messageMatch
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header section
                HStack {
                    Text("Conversa")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    if !isSearching {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSearching = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search bar
                if isSearching {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Search chats...", text: $searchText)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSearching = false
                                searchText = ""
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
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
                            ForEach(filteredChats, id: \.id) { chat in
                                NavigationLink(value: chat.id) {
                                    ChatRowView(chat: chat, currentUserId: currentUser?.uid ?? "")
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(
                                    LongPressGesture(minimumDuration: 0.5)
                                        .onEnded { _ in
                                            chatToDelete = chat
                                            showingDeleteAlert = true
                                        }
                                )
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        print("Opening chat with ID: \(chat.id), Other User ID: \(chat.otherUserId)")
                                    }
                                )
                                
                                Divider()
                                    .padding(.leading, 70)
                                    .padding(.trailing, 10)
                            }
                            
                            if filteredChats.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No chats found")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                    Text("Try searching with different keywords")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 50)
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
                    .onDisappear {
                        // Refresh unread counts when returning from chat
                        refreshUnreadCounts()
                    }
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
            refreshUnreadCounts()
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
    
    private func refreshUnreadCounts() {
    guard let currentUserId = Auth.auth().currentUser?.uid else { return }
    
    for (index, chat) in chats.enumerated() {
        Firestore.firestore()
            .collection("chats")
            .document(chat.id)
            .collection("messages")
            .whereField("senderId", isEqualTo: chat.otherUserId)
            .getDocuments { messageSnapshot, error in
                var unreadCount = 0
                
                if let messages = messageSnapshot?.documents {
                    for messageDoc in messages {
                        let messageData = messageDoc.data()
                        let readBy = messageData["readBy"] as? [String] ?? []
                        let deletedFor = messageData["deletedFor"] as? [String] ?? []
                        let isDeleted = messageData["deleted"] as? Bool ?? false
                        
                        if !readBy.contains(currentUserId) && 
                           !deletedFor.contains(currentUserId) && 
                           !isDeleted {
                            unreadCount += 1
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if index < self.chats.count && self.chats[index].id == chat.id {
                        self.chats[index] = ChatItem(
                            id: chat.id,
                            otherUserId: chat.otherUserId,
                            lastMessage: chat.lastMessage,
                            lastMessageTime: chat.lastMessageTime,
                            lastMessageSenderId: chat.lastMessageSenderId,
                            isUnread: chat.isUnread,
                            unreadCount: unreadCount
                        )
                    }
                }
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
                    let group = DispatchGroup()
                    
                    for document in documents {
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        let otherUserId = participants.first { $0 != currentUserId } ?? ""
                        
                        // Filter out blocked users
                        if blockedUsers.contains(otherUserId) || blockedBy.contains(otherUserId) {
                            continue
                        }
                        
                        // Load user data for search functionality
                        group.enter()
                        UserCacheManager.shared.getUser(uid: otherUserId) { user in
                            if let user = user {
                                DispatchQueue.main.async {
                                    self.chatUsers[otherUserId] = user
                                }
                            }
                            group.leave()
                        }
                        
                        let lastMessage = data["lastMessage"] as? [String: Any] ?? [:]
                        let lastMessageText = lastMessage["text"] as? String ?? ""
                        let lastMessageTimestamp = lastMessage["timestamp"] as? Timestamp ?? Timestamp()
                        let lastMessageSenderId = lastMessage["senderId"] as? String ?? ""
                        
                        let lastMessageRead = data["lastMessageRead"] as? [String: Bool] ?? [:]
                        let isUnread = !(lastMessageRead[currentUserId] ?? true)
                        
                        // Count unread messages by querying the messages subcollection
                        group.enter()
                        Firestore.firestore()
                            .collection("chats")
                            .document(document.documentID)
                            .collection("messages")
                            .whereField("senderId", isEqualTo: otherUserId)
                            .getDocuments { messageSnapshot, messageError in
                                var unreadCount = 0
                                
                                if let messages = messageSnapshot?.documents {
                                    for messageDoc in messages {
                                        let messageData = messageDoc.data()
                                        let readBy = messageData["readBy"] as? [String] ?? []
                                        let deletedFor = messageData["deletedFor"] as? [String] ?? []
                                        let isDeleted = messageData["deleted"] as? Bool ?? false
                                        
                                        // Count if message is not read by current user and not deleted
                                        if !readBy.contains(currentUserId) && 
                                           !deletedFor.contains(currentUserId) && 
                                           !isDeleted {
                                            unreadCount += 1
                                        }
                                    }
                                }
                                
                                let chatItem = ChatItem(
                                    id: document.documentID,
                                    otherUserId: otherUserId,
                                    lastMessage: lastMessageText,
                                    lastMessageTime: lastMessageTimestamp.dateValue(),
                                    lastMessageSenderId: lastMessageSenderId,
                                    isUnread: isUnread,
                                    unreadCount: unreadCount
                                )
                                
                                newChats.append(chatItem)
                                group.leave()
                            }
                    }
                    
                    group.notify(queue: .main) {
                        self.chats = newChats.sorted { $0.lastMessageTime > $1.lastMessageTime }
                        self.isLoading = false
                        print("Loaded \(self.chats.count) chats with unread counts")
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
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(otherUser?.fullName ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(formatTime(chat.lastMessageTime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        // Unread count badge
                        if chat.unreadCount > 0 {
                            Text("\(chat.unreadCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
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
                }
                
                Text(chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
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
    let unreadCount: Int
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


