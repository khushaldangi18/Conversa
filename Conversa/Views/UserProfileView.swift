import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    let userId: String
    @State private var user: User?
    @State private var isLoading = true
    @State private var onlineStatus = "offline"
    @State private var sharedImages: [String] = []
    @State private var isLoadingImages = false
    @State private var showingImagePreview = false
    @State private var previewImageURL = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if let user = user {
                    // Profile Image
                    if !user.photoURL.isEmpty, let url = URL(string: user.photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4 ) {
                        Text(user.username.isEmpty ? user.fullName : user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if !user.username.isEmpty {
                            Text(user.fullName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(onlineStatus == "online" ? Color.green : Color.black.opacity(0.5))
                                .frame(width: 6, height: 6)
                            Text(onlineStatus == "online" ? "Online" : "Offline")
                                .foregroundStyle(onlineStatus == "online" ? .green : .black.opacity(0.5))
                                .font(.caption)
                            
                        }
                    }
                    
                    // Shared Images Section
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text("Shared Media")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(EdgeInsets(top: 2, leading: 0, bottom: 5, trailing: 0))
                            Spacer()
                            
                            if isLoadingImages {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal)
                        
                        if sharedImages.isEmpty && !isLoadingImages {
                            Text("No shared media")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3), spacing: 1) {
                                    ForEach(sharedImages, id: \.self) { imageURL in
                                        AsyncImage(url: URL(string: imageURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 130, height: 130)
                                                .clipped()
                                                .onTapGesture {
                                                    previewImageURL = imageURL
                                                    showingImagePreview = true
                                                }
                                        }
                                        placeholder: {
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                                .frame(width: 130, height: 130)
                                                .overlay(
                                                    ProgressView()
                                                        .scaleEffect(0.6)
                                                )
                                        }
                                        .padding(1)
                                        
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            //            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadUser()
        }
        .sheet(isPresented: $showingImagePreview) {
            ImagePreviewView(imageURL: previewImageURL)
        }
    }
    
    private func loadUser() {
        UserCacheManager.shared.getUser(uid: userId) { user in
            DispatchQueue.main.async {
                self.user = user
                self.isLoading = false
                if user != nil {
                    observeUserStatus()
                    loadSharedImages()
                }
            }
        }
    }
    
    private func observeUserStatus() {
        PresenceManager.shared.observeUserStatus(for: userId) { status, _ in
            DispatchQueue.main.async {
                self.onlineStatus = status
            }
        }
    }
    
    private func loadSharedImages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoadingImages = true
        
        // Find chat between current user and this user
        Firestore.firestore()
            .collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching chats: \(error)")
                    self.isLoadingImages = false
                    return
                }
                
                // Find the chat that contains both users
                let chatDocs = snapshot?.documents.filter { doc in
                    let participants = doc.data()["participants"] as? [String] ?? []
                    return participants.contains(self.userId)
                }
                
                guard let chatDoc = chatDocs?.first else {
                    print("No chat found between users")
                    self.isLoadingImages = false
                    return
                }
                
                let chatId = chatDoc.documentID
                print("Found chat ID: \(chatId)")
                
                // Fetch image messages from this chat
                Firestore.firestore()
                    .collection("chats")
                    .document(chatId)
                    .collection("messages")
                    .whereField("type", isEqualTo: "image")
                    .getDocuments { snapshot, error in
                        self.isLoadingImages = false
                        
                        if let error = error {
                            print("Error fetching images: \(error)")
                            return
                        }
                        
                        print("Found \(snapshot?.documents.count ?? 0) image messages")
                        
                        // Sort by timestamp in code instead of in query
                        let sortedDocs = snapshot?.documents.sorted { doc1, doc2 in
                            let timestamp1 = (doc1.data()["timestamp"] as? Timestamp)?.dateValue() ?? Date.distantPast
                            let timestamp2 = (doc2.data()["timestamp"] as? Timestamp)?.dateValue() ?? Date.distantPast
                            return timestamp1 > timestamp2
                        } ?? []
                        
                        let imageURLs: [String] = sortedDocs.compactMap { doc in
                            let data = doc.data()
                            let deleted = data["deleted"] as? Bool ?? false
                            let deletedFor = data["deletedFor"] as? [String] ?? []
                            guard !deleted && !deletedFor.contains(currentUserId),
                                    let imageURL = data["text"] as? String else {
                                return nil
                            }
                            print("Found image URL: \(imageURL)")
                            return imageURL
                        }
                        
                        DispatchQueue.main.async {
                            self.sharedImages = imageURLs
                            print("Updated sharedImages with \(imageURLs.count) images")
                        }
                    }
            }
    }
}
