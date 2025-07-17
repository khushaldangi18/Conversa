import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore


class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    override init() {
        // Remove the Firebase configuration since it's already done in ConversaApp.swift
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        super.init()
    }
}


struct AuthView: View {
    @State private var isLogin = true
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 15) {
                        Spacer(minLength: 60)
                        
                        
//                        ZStack {
//                            Rectangle()
//                                .fill(LinearGradient(
//                                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                ))
//                                .frame(width: 20, height: 20)
//                            
//                            Image("Logo")
//                                .resizable()
//                                .scaledToFit()
//                                .font(.system(size: 20, weight: .light))
//                                .foregroundStyle(LinearGradient(
//                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                ))
//                        }
                        
                        VStack(spacing: 10) {
                            // App icon
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            
                            Text("Conversa")
                                .font(.system(size: 36, weight: .thin, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Connect with friends")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 15)
                        }
                        
                    }
                    .frame(minHeight: geometry.size.height * 0.32)
                    
                    // Auth section
                    VStack(spacing: 32) {
                        // Tab selector
                        HStack(spacing: 0) {
                            ForEach([("Sign In", true), ("Sign Up", false)], id: \.0) { title, isLoginTab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        isLogin = isLoginTab
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(title)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(isLogin == isLoginTab ? .primary : .secondary)
                                        
                                        Rectangle()
                                            .fill(isLogin == isLoginTab ? Color.blue : Color.clear)
                                            .frame(height: 2)
                                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLogin)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Content
                        Group {
                            if isLogin {
                                LoginView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                RegisterView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            }
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLogin)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var loginStatusMessage = ""
    @State private var isLoggedIn = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 20) {
                // Email field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Email Address")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Enter your email", text: $email)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lock")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 20)
                        
                        Text("Password")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    SecureField("Enter your password", text: $password)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .disabled(isLoading)
                }
            }
            .padding(.horizontal, 40)
            
            // Sign in button
            Button(action: {
                login()
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(isLoading ? "Signing In..." : "Sign In")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.blue)
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
            .disabled(isLoading)
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isLoading)
            
            if !loginStatusMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text(loginStatusMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 40)
            }
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            ContentView()
        }
    }
    
    func login() {
        isLoading = true
        loginStatusMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            
            if let error = error {
                self.loginStatusMessage = "Failed to login: \(error.localizedDescription)"
                print(self.loginStatusMessage)
                return
            }
            
            self.loginStatusMessage = "Successfully logged in as \(result?.user.email ?? "")"
            print(self.loginStatusMessage)
            
            // Set isLoggedIn to true to trigger navigation to ContentView
            self.isLoggedIn = true
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
    @State private var isLoggedIn = false
    @State private var isRegistering = false
    
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
        VStack(spacing: 28) {
            // Profile Image Section
            VStack(spacing: 12) {
                Button {
                    showImagePicker.toggle()
                } label: {
                    ZStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        } else {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 34, weight: .medium))
                                        .foregroundColor(.blue)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        // Edit overlay
//                        Circle()
//                            .fill(Color.blue)
//                            .frame(width: 28, height: 28)
//                            .overlay(
//                                Image(systemName: "plus")
//                                    .font(.system(size: 12, weight: .bold))
//                                    .foregroundColor(.white)
//                            )
//                            .offset(x: 30, y: 30)
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage)
                }
                .disabled(isRegistering)
                
                Text("Add Profile Photo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Form Fields
            VStack(spacing: 20) {
                // Full Name
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "person")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        Text("Full Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Enter your full name", text: $fullName)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .autocapitalization(.words)
                        .disabled(isRegistering)
                }
                
                // Username
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "at")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Username")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        TextField("Choose a username", text: $username)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .disabled(isRegistering)
                            .onChange(of: username) { newValue in
                                let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                if filtered != newValue {
                                    username = filtered
                                }
                                
                                if !username.isEmpty {
                                    isUsernameValid = true
                                    usernameMessage = ""
                                    checkUsernameUniqueness()
                                }
                            }
                        
                        if isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isUsernameValid ? Color.blue.opacity(0.2) : Color.red.opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                    )
                    
                    if !usernameMessage.isEmpty {
                        HStack {
                            Image(systemName: isUsernameValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(isUsernameValid ? .green : .red)
                            
                            Text(usernameMessage)
                                .font(.system(size: 13))
                                .foregroundColor(isUsernameValid ? .green : .red)
                        }
                    }
                }
                
                // Email
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 20)
                        
                        Text("Email Address")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Enter your email", text: $email)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isRegistering)
                }
                
                // Password
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lock")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        Text("Password")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    SecureField("Create a password", text: $password)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isPasswordValid ? Color.green.opacity(0.2) : Color.red.opacity(0.5),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .disabled(isRegistering)
                        .onChange(of: password) { _ in
                            isPasswordValid = passwordCriteria
                            passwordMessage = isPasswordValid ? "" : "8+ characters, 1 uppercase, 1 number"
                        }
                    
                    if !passwordMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            
                            Text(passwordMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            // Create Account Button
            Button(action: {
                validateAndRegister()
            }) {
                HStack(spacing: 12) {
                    if isRegistering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(isRegistering ? "Creating Account..." : "Create Account")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.blue)
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
            .disabled(!isUsernameValid || !isPasswordValid || isCheckingUsername || isRegistering)
            .scaleEffect(isRegistering ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isRegistering)
            
            if !loginStatusMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text(loginStatusMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 40)
            }
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            ContentView()
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
        isRegistering = true
        loginStatusMessage = ""
        register()
    }
    
    func register() {
        // Create user account first
        Auth.auth().createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                self.loginStatusMessage = "Failed to create user: \(err.localizedDescription)"
                self.isRegistering = false
                return
            }
            
            guard let uid = result?.user.uid else { 
                self.isRegistering = false
                return 
            }
            
            // Check username uniqueness with authenticated user
            FirebaseManager.shared.firestore.collection("users")
                .whereField("username", isEqualTo: self.username)
                .getDocuments { snapshot, error in
                    if let error = error {
                        self.loginStatusMessage = "Error checking username: \(error.localizedDescription)"
                        self.isRegistering = false
                        result?.user.delete()
                        return
                    }
                    
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        self.loginStatusMessage = "Username already taken. Please choose another."
                        self.isRegistering = false
                        result?.user.delete()
                        return
                    }
                    
                    // Username is unique, save user data
                    let userData: [String: Any] = [
                        "email": self.email,
                        "fullName": self.fullName,
                        "username": self.username.lowercased(),
                        "createdAt": Timestamp(),
                        "lastActive": Timestamp(),
                        "status": "online"
                    ]
                    
                    FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { error in
                        if let error = error {
                            self.loginStatusMessage = "Failed to save user data: \(error.localizedDescription)"
                            self.isRegistering = false
                            return
                        }
                        
                        // Continue with image upload or set default
                        if let selectedImage = self.selectedImage {
                            self.persistImageToStorage()
                        } else {
                            // Set default image URL
                            let defaultImageData: [String: Any] = [
                                "photoURL": "https://firebasestorage.googleapis.com/v0/b/chatora-f12b1.firebasestorage.app/o/default_image.jpg?alt=media&token=a70a47b0-5834-491a-85d4-941b156519e3"
                            ]
                            
                            FirebaseManager.shared.firestore.collection("users").document(uid).updateData(defaultImageData) { error in
                                if let error = error {
                                    print("Failed to set default image URL: \(error)")
                                }
                                
                                self.isRegistering = false
                                self.isLoggedIn = true
                            }
                        }
                    }
                }
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { 
            self.isRegistering = false
            return 
        }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        guard let imageData = self.selectedImage?.jpegData(compressionQuality: 0.5) else {
            self.isRegistering = false
            self.isLoggedIn = true
            return
        }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to storage \(err)"
                self.isRegistering = false
                return
            }
            
            ref.downloadURL { url, err in
                self.isRegistering = false
                
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    self.isLoggedIn = true
                    return
                }
                
                guard let url = url else { 
                    self.isLoggedIn = true
                    return 
                }
                
                // Update the user document with the photo URL
                let userData = ["photoURL": url.absoluteString]
                Firestore.firestore().collection("users").document(uid).updateData(userData) { error in
                    if let error = error {
                        print("Failed to update user photo URL: \(error)")
                    }
                    
                    // Set isLoggedIn to true to trigger navigation to ContentView
                    self.isLoggedIn = true
                }
            }
        }
    }
}

//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(parent: self)
//    }
//    
//    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//        let parent: ImagePicker
//        
//        init(parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            if let image = info[.originalImage] as? UIImage {
//                parent.image = image
//            }
//            picker.dismiss(animated: true)
//        }
//        
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            picker.dismiss(animated: true)
//        }
//    }
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
