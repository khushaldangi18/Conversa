import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var requests: [ChatRequest] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading requests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if requests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No chat requests")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(requests, id: \.id) { request in
                        ChatRequestRow(request: request) { action in
                            handleRequest(request, action: action)
                        }
                    }
                }
            }
            .navigationTitle("Chat Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadChatRequests()
        }
    }
    
    private func loadChatRequests() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("chatRequests")
            .whereField("recipientId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading chat requests: \(error)")
                    self.isLoading = false
                    return
                }
                
                self.requests = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return ChatRequest(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        recipientId: data["recipientId"] as? String ?? "",
                        message: data["message"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "pending"
                    )
                } ?? []
                
                self.isLoading = false
            }
    }
    
    private func handleRequest(_ request: ChatRequest, action: RequestAction) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        if action == .accept {
            // Accept request: Update status and create chat
            let batch = FirebaseManager.shared.firestore.batch()
            
            // Update request status to accepted
            let requestRef = FirebaseManager.shared.firestore.collection("chatRequests").document(request.id)
            batch.updateData(["status": "accepted"], forDocument: requestRef)
            
            // Create new chat
            let newChatData: [String: Any] = [
                "participants": [request.senderId, request.recipientId],
                "createdAt": Timestamp(),
                "lastMessage": [
                    "text": "",
                    "senderId": "",
                    "timestamp": Timestamp(),
                    "type": "text"
                ],
                "lastMessageRead": [
                    request.senderId: true,
                    request.recipientId: true
                ]
            ]
            
            let chatRef = FirebaseManager.shared.firestore.collection("chats").document()
            batch.setData(newChatData, forDocument: chatRef)
            
            batch.commit { error in
                if let error = error {
                    print("Error accepting request: \(error)")
                } else {
                    print("Request accepted successfully")
                    // Remove the manual array update - let the listener handle it
                }
            }
        } else {
            // Reject request: Update status to rejected
            let requestRef = FirebaseManager.shared.firestore.collection("chatRequests").document(request.id)
            requestRef.updateData(["status": "rejected"]) { error in
                if let error = error {
                    print("Error rejecting request: \(error)")
                } else {
                    print("Request rejected successfully")
                    // Remove the manual array update - let the listener handle it
                }
            }
        }
    }
}

struct ChatRequestRow: View {
    let request: ChatRequest
    let onAction: (RequestAction) -> Void
    @State private var senderUser: User?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let photoURL = senderUser?.photoURL, let url = URL(string: photoURL) {
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(senderUser?.fullName ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                
                if !request.message.isEmpty {
                    Text(request.message)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Text(formatTime(request.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onAction(.reject)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    onAction(.accept)
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadSenderUser()
        }
    }
    
    private func loadSenderUser() {
        UserCacheManager.shared.getUser(uid: request.senderId) { user in
            DispatchQueue.main.async {
                self.senderUser = user
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ChatRequest {
    let id: String
    let senderId: String
    let recipientId: String
    let message: String
    let timestamp: Date
    let status: String
}

enum RequestAction {
    case accept, reject
}
