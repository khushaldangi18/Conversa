import SwiftUI
import Firebase
import FirebaseFirestore

struct HelpFeedbackView: View {
    @State private var userQuery = ""
    @State private var isSubmitting = false
    @State private var showingThankYouAlert = false
    @State private var currentUser: ChatUser?
    
    private let faqs = [
        FAQ(question: "How do I change my profile picture?", 
            answer: "Go to Profile > Edit Profile and tap on your profile picture to change it."),
        FAQ(question: "How do I block/unblock users?", 
            answer: "You can block users from their profile or chat. To unblock, go to Profile > Blocked Users."),
        FAQ(question: "How do I delete messages?", 
            answer: "Long press on any message to delete it. This will remove it from your view only."),
        FAQ(question: "How do I know if someone is online?", 
            answer: "Online users will show a green 'Online' status in chats and their profile."),
        FAQ(question: "Can I send images in chat?", 
            answer: "Yes! Tap the photo icon next to the message input to send images."),
        FAQ(question: "How do I sign out?", 
            answer: "Go to Profile and tap the 'Sign Out' button at the bottom of the screen."),
        FAQ(question: "How do I search for new users?", 
            answer: "Tap the '+' button on the main chat screen and search by username."),
        FAQ(question: "Are my messages encrypted?", 
            answer: "Your messages are securely stored and transmitted using Firebase's security protocols.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // FAQ Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        Text("Frequently Asked Questions")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(faqs, id: \.question) { faq in
                            FAQRowView(faq: faq)
                        }
                    }
                }
                
                // Divider
                Divider()
                    .padding(.horizontal)
                
                // Feedback Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        Text("Send us your feedback")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Have a question or suggestion? We'd love to hear from you!")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // Query Input Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your message")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Write your question or feedback here...", text: $userQuery, axis: .vertical)
                                    .lineLimit(5...10)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal)
                            
                            // Submit Button
                            Button(action: submitQuery) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 16))
                                        Text("Send Feedback")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                                )
                            }
                            .disabled(userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Help & Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentUser()
        }
        .alert("Thank You!", isPresented: $showingThankYouAlert) {
            Button("OK") { }
        } message: {
            Text("Thank you for writing your review. We will reply you soon.")
        }
    }
    
    private func loadCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            
            let uid = data["uid"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            let profileImageUrl = data["photoURL"] as? String ?? ""
            
            self.currentUser = ChatUser(
                uid: uid,
                email: email,
                username: username,
                profileImageUrl: profileImageUrl,
                fullName: data["fullName"] as? String ?? ""
            )
        }
    }
    
    private func submitQuery() {
        guard !userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let user = currentUser else { return }
        
        isSubmitting = true
        
        let queryData: [String: Any] = [
            "message": userQuery.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": user.email,
            "username": user.username,
            "uid": user.uid,
            "timestamp": Timestamp(),
            "status": "pending" // pending, replied, resolved
        ]
        
        FirebaseManager.shared.firestore.collection("queries").addDocument(data: queryData) { error in
            isSubmitting = false
            
            if let error = error {
                print("Failed to submit query: \(error)")
                return
            }
            
            // Clear the input and show thank you message
            userQuery = ""
            showingThankYouAlert = true
        }
    }
}

struct FAQ {
    let question: String
    let answer: String
}

struct FAQRowView: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Text(faq.answer)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.5))
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

#Preview {
    HelpFeedbackView()
}
