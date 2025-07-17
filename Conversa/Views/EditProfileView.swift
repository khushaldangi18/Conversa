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
        NavigationView {
            VStack(spacing: 20) {
                // Profile Image Section
                VStack(spacing: 10) {
                    Button {
                        showImagePicker = true
                    } label: {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        } else if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.gray)
                        }
                    }
                    .disabled(isUpdating)
                    
                    Text("Tap to change profile photo")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Username Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if !usernameMessage.isEmpty {
                        Text(usernameMessage)
                            .font(.caption)
                            .foregroundColor(isUsernameValid ? .green : .red)
                    }
                }
                
                // Update Button
                Button(action: updateProfile) {
                    if isUpdating {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Updating...")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    } else {
                        Text("Update Profile")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isUpdating || !isUsernameValid || isCheckingUsername)
                .padding(.top, 20)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                username = currentUser?.username ?? ""
            }
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