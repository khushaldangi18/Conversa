import SwiftUI
import Firebase

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isProfilePublic: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Type Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Type")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        // Public Profile Option
                        Button {
                            updateProfileType(isPublic: true)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .foregroundColor(.green)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Public")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Anyone can start a chat with you")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isProfilePublic {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                        }
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        // Private Profile Option
                        Button {
                            updateProfileType(isPublic: false)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundColor(.orange)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Private")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Others need to send a request to chat")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !isProfilePublic {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateProfileType(isPublic: Bool) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).updateData([
            "isPublic": isPublic
        ]) { error in
            if let error = error {
                print("Failed to update profile type: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.isProfilePublic = isPublic
                }
            }
        }
    }
}