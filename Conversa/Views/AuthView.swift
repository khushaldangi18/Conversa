import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore


class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    static let shared = FirebaseManager()
    
    override init() {
        // Remove the Firebase configuration since it's already done in ConversaApp.swift
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        super.init()
    }
}


struct AuthView: View {
    @State private var isLogin = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isLogin ? "Login" : "Create Account")
                .font(.system(size: 28, weight: .bold))
            
            HStack(spacing: 0) {
                Button(action: {
                    isLogin = true
                }) {
                    Text("Login")
                        .foregroundColor(isLogin ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isLogin ? Color.white : Color(.systemGray5))
                        .cornerRadius(8)
                }

                Button(action: {
                    isLogin = false
                }) {
                    Text("Create Account")
                        .foregroundColor(!isLogin ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!isLogin ? Color.white : Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .background(Color(.systemGray5))
            .clipShape(Capsule())
            .padding(.horizontal)

            // Show either LoginView or RegisterView based on selection
            if isLogin {
                LoginView()
            } else {
                RegisterView()
            }

            Spacer()
        }
        .padding(.top, 40)
        .background(Color(.systemGray6))
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var loginStatusMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
            Button(action: {
                login()
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
            
            if !loginStatusMessage.isEmpty {
                Text(loginStatusMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
        }
        .padding(.horizontal)
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.loginStatusMessage = "Failed to login: \(error.localizedDescription)"
                print(self.loginStatusMessage)
                return
            }
            
            self.loginStatusMessage = "Successfully logged in as \(result?.user.email ?? "")"
            print(self.loginStatusMessage)
        }
    }
}

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var loginStatusMessage = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isCheckingUsername = false
    
    // Validation states
    @State private var isUsernameValid = true
    @State private var isPasswordValid = true
    @State private var usernameMessage = ""
    @State private var passwordMessage = ""
    
    // Password validation criteria
    private var passwordCriteria: Bool {
        password.count >= 8 && 
        password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image Picker
            Button {
                showImagePicker.toggle()
            } label: {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }.sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }

            Text("Tap to add profile photo")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Full Name", text: $fullName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.words)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .onChange(of: username) { newValue in
                            // Only allow alphanumeric characters and underscores
                            let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                            if filtered != newValue {
                                username = filtered
                            }
                            
                            // Check username availability after typing stops
                            if !username.isEmpty {
                                isUsernameValid = true
                                usernameMessage = ""
                                checkUsernameUniqueness()
                            }
                        }
                    
                    if isCheckingUsername {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isUsernameValid ? Color.clear : Color.red, lineWidth: 1)
                )
                
                if !usernameMessage.isEmpty {
                    Text(usernameMessage)
                        .font(.caption)
                        .foregroundColor(isUsernameValid ? .green : .red)
                        .padding(.leading, 4)
                }
            }
            
            TextField("Email", text: $email)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            VStack(alignment: .leading, spacing: 4) {
                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: password) { _ in
                        isPasswordValid = passwordCriteria
                        passwordMessage = isPasswordValid ? "" : "Password must be at least 8 characters with 1 uppercase letter and 1 number"
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPasswordValid ? Color.clear : Color.red, lineWidth: 1)
                    )
                
                if !passwordMessage.isEmpty {
                    Text(passwordMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
            }
                
            Button(action: {
                validateAndRegister()
            }) {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
            .disabled(!isUsernameValid || !isPasswordValid || isCheckingUsername)
            
            if !loginStatusMessage.isEmpty {
                Text(loginStatusMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
        }
        .padding(.horizontal)
    }
    
    private func checkUsernameUniqueness() {
        guard username.count >= 3 else {
            isUsernameValid = false
            usernameMessage = "Username must be at least 3 characters"
            return
        }
        
        isCheckingUsername = true
        
        Firestore.firestore().collection("users")
            .whereField("username", isEqualTo: username)
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
    
    private func validateAndRegister() {
        // Validate all fields
        if fullName.isEmpty {
            loginStatusMessage = "Please enter your full name"
            return
        }
        
        if username.isEmpty || !isUsernameValid {
            loginStatusMessage = "Please enter a valid username"
            return
        }
        
        if email.isEmpty {
            loginStatusMessage = "Please enter your email"
            return
        }
        
        if password.isEmpty || !isPasswordValid {
            loginStatusMessage = "Please enter a valid password"
            return
        }
        
        // All validations passed, proceed with registration
        register()
    }
    
    func register() {
        // First check username uniqueness one more time
        Firestore.firestore().collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.loginStatusMessage = "Error checking username: \(error.localizedDescription)"
                    return
                }
                
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    self.loginStatusMessage = "Username already taken. Please choose another."
                    return
                }
                
                // Username is unique, proceed with account creation
                Auth.auth().createUser(withEmail: email, password: password) { result, err in
                    if let err = err {
                        self.loginStatusMessage = "Failed to create user: \(err.localizedDescription)"
                        return
                    }
                    
                    guard let uid = result?.user.uid else { return }
                    self.loginStatusMessage = "Successfully created user \(uid)"
                    
                    // Save user data to Firestore
                    let userData: [String: Any] = [
                        "email": self.email,
                        "fullName": self.fullName,
                        "username": self.username,
                        "createdAt": Timestamp(),
                        "lastActive": Timestamp(),
                        "status": "online"
                    ]
                    
                    Firestore.firestore().collection("users").document(uid).setData(userData) { error in
                        if let error = error {
                            self.loginStatusMessage = "Failed to save user data: \(error.localizedDescription)"
                            return
                        }
                        
                        // Continue with image upload if an image was selected
                        self.persistImageToStorage()
                    }
                }
            }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        guard let imageData = self.selectedImage?.jpegData(compressionQuality: 0.5) else {
            return
        }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to storage \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                guard let url = url else { return }
                self.loginStatusMessage = "Successfully stored image with url: \(url.absoluteString)"
                print(url.absoluteString)
                
                // Update the user document with the photo URL
                let userData = ["photoURL": url.absoluteString]
                Firestore.firestore().collection("users").document(uid).updateData(userData) { error in
                    if let error = error {
                        print("Failed to update user photo URL: \(error)")
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}