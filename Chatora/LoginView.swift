//
//  LoginView.swift
//  Chatora
//
//  Created by FCP 21 on 08/07/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecureField: Bool = true
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showingRegisterView: Bool = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 20) {
                            Spacer()
                                .frame(height: geometry.size.height * 0.1)

                            // App Logo/Icon
                            Image(systemName: "message.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

                            // App Name
                            Text("Chatora")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Connect with friends instantly")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                            .frame(height: 60)

                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                TextField("Enter your email", text: $email)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack {
                                    if isSecureField {
                                        SecureField("Enter your password", text: $password)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    } else {
                                        TextField("Enter your password", text: $password)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }

                                    Button(action: {
                                        isSecureField.toggle()
                                    }) {
                                        Image(systemName: isSecureField ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 8)
                                    }
                                }
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    resetPassword()
                                }
                                .font(.footnote)
                                .foregroundColor(.blue)
                            }

                            // Login Button
                            Button(action: {
                                loginUser()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isLoading ? "Signing In..." : "Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)

                            // Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("or")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.vertical, 10)

                            // Sign Up Button
                            Button(action: {
                                // Navigate to register view
                                showingRegisterView = true
                            }) {
                                Text("Create New Account")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Alert", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isLoggedIn) {
            // Navigate to main chat view after successful login
            Text("Welcome to Chatora!")
                .font(.largeTitle)
                .padding()
        }
        .sheet(isPresented: $showingRegisterView) {
            RegisterView()
        }
    }

    // MARK: - Helper Functions
    private func loginUser() {
        // Basic validation
        guard isValidEmail(email) else {
            showAlert(message: "Please enter a valid email address")
            return
        }

        guard password.count >= 6 else {
            showAlert(message: "Password must be at least 6 characters long")
            return
        }

        isLoading = true

        // Firebase Authentication
        Task {
            do {
                let user = try await authManager.signIn(email: email, password: password)

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoggedIn = true
                }

                print("User logged in successfully: \(user.email)")

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let authError = error as? AuthError {
                        self.showAlert(message: authError.localizedDescription ?? "Login failed")
                    } else {
                        self.showAlert(message: "Login failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func resetPassword() {
        guard isValidEmail(email) else {
            showAlert(message: "Please enter a valid email address first")
            return
        }

        Task {
            do {
                try await authManager.resetPassword(email: email)

                DispatchQueue.main.async {
                    self.showAlert(message: "Password reset email sent to \(self.email)")
                }

            } catch {
                DispatchQueue.main.async {
                    if let authError = error as? AuthError {
                        self.showAlert(message: authError.localizedDescription ?? "Failed to send password reset email")
                    } else {
                        self.showAlert(message: "Failed to send password reset email: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }




}



#Preview {
    LoginView()
}
 
