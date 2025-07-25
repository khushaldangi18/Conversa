import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUpdating = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameValid = true
    @State private var usernameMessage = ""
    
    let currentUser: ChatUser?
    let profileImage: UIImage?
    let onUpdate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
                VStack(spacing: 16) {
                    Text("Edit Your Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Update your profile information and photo")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Profile Image Section
                VStack(spacing: 16) {
                    Button {
                        showImagePicker = true
                    } label: {
                        ZStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.blue, .purple]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            } else if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.blue, .purple]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray.opacity(0.6))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                            
                            // Camera overlay
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                                .offset(x: 45, y: 45)
                        }
                    }
                    .disabled(isUpdating)
                    .scaleEffect(isUpdating ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isUpdating)
                    
                    VStack(spacing: 4) {
                        Text("Tap to change profile photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Choose a photo that represents you")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Username Section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "at")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("Username")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                TextField("Enter username", text: $username)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                isUsernameValid ? Color.clear : Color.red.opacity(0.5),
                                                lineWidth: 1
                                            )
                                    )
                                    .autocapitalization(.none)
                                    .disabled(isUpdating)
                                    .onChange(of: username) { newValue in
                                        let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                        if filtered != newValue {
                                            username = filtered
                                        }
                                        
                                        if !username.isEmpty && username != currentUser?.username {
                                            checkUsernameUniqueness()
                                        } else {
                                            isUsernameValid = true
                                            usernameMessage = ""
                                        }
                                    }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .padding(.trailing, 8)
                                }
                            }
                            
                            if !usernameMessage.isEmpty {
                                HStack {
                                    Image(systemName: isUsernameValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(isUsernameValid ? .green : .red)
                                    
                                    Text(usernameMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(isUsernameValid ? .green : .red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        Text("Username must be at least 3 characters and can only contain letters, numbers, and underscores.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                // Status Messages
                if !errorMessage.isEmpty || !successMessage.isEmpty {
                    VStack(spacing: 8) {
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        
                        if !successMessage.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 40)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Update Button - Fixed at bottom
            Button(action: updateProfile) {
                HStack(spacing: 12) {
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text("Updating Profile...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Update Profile")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isUpdating || !isUsernameValid || isCheckingUsername)
            .opacity((isUpdating || !isUsernameValid || isCheckingUsername) ? 0.6 : 1.0)
            .scaleEffect(isUpdating ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isUpdating)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            username = currentUser?.username ?? ""
        }
    }
    
    private func checkUsernameUniqueness() {
        guard username.count >= 3 else {
            isUsernameValid = false
            usernameMessage = "Username must be at least 3 characters"
            return
        }
        
        isCheckingUsername = true
        
        FirebaseManager.shared.firestore.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
            .getDocuments { snapshot, error in
                isCheckingUsername = false
                
                if let error = error {
                    print("Failed to check username: \(error)")
                    return
                }
                
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    isUsernameValid = false
                    usernameMessage = "Username already taken"
                } else {
                    isUsernameValid = true
                    usernameMessage = "Username available"
                }
            }
    }
    
    private func updateProfile() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isUpdating = true
        errorMessage = ""
        successMessage = ""
        
        var updateData: [String: Any] = [:]
        
        // Update username if changed
        if username != currentUser?.username && !username.isEmpty {
            updateData["username"] = username.lowercased()
        }
        
        // Update profile image if selected
        if let selectedImage = selectedImage {
            uploadProfileImage(uid: uid) { imageUrl in
                if let imageUrl = imageUrl {
                    updateData["photoURL"] = imageUrl
                }
                
                self.updateUserData(uid: uid, data: updateData)
            }
        } else {
            updateUserData(uid: uid, data: updateData)
        }
    }
    
    private func uploadProfileImage(uid: String, completion: @escaping (String?) -> Void) {
        guard let selectedImage = selectedImage,
              let imageData = selectedImage.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload image: \(error)")
                completion(nil)
                return
            }
            
            ref.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    private func updateUserData(uid: String, data: [String: Any]) {
        guard !data.isEmpty else {
            isUpdating = false
            successMessage = "No changes to update"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).updateData(data) { error in
            isUpdating = false
            
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                successMessage = "Profile updated successfully!"
                onUpdate()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}
