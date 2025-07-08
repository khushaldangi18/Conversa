//
//  RegisterView.swift
//  Chatora
//
//  Created by FCP 21 on 08/07/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordSecure: Bool = true
    @State private var isConfirmPasswordSecure: Bool = true
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistered: Bool = false
    @State private var agreeToTerms: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 15) {
                            Spacer()
                                .frame(height: geometry.size.height * 0.05)

                            // App Logo/Icon
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)

                            // Title
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Join Chatora and start connecting")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)

                        Spacer()
                            .frame(height: 40)

                        // Registration Form
                        VStack(spacing: 20) {
                            // Full Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                TextField("Enter your full name", text: $fullName)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }

                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                TextField("Choose a username", text: $username)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)

                                if !username.isEmpty && !isValidUsername(username) {
                                    Text("Username must be 3-20 characters, letters and numbers only")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

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

                                if !email.isEmpty && !isValidEmail(email) {
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack {
                                    if isPasswordSecure {
                                        SecureField("Create a password", text: $password)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    } else {
                                        TextField("Create a password", text: $password)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }

                                    Button(action: {
                                        isPasswordSecure.toggle()
                                    }) {
                                        Image(systemName: isPasswordSecure ? "eye.slash" : "eye")
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

                                if !password.isEmpty && !isValidPassword(password) {
                                    Text("Password must be at least 8 characters with uppercase, lowercase, and number")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack {
                                    if isConfirmPasswordSecure {
                                        SecureField("Confirm your password", text: $confirmPassword)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    } else {
                                        TextField("Confirm your password", text: $confirmPassword)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }

                                    Button(action: {
                                        isConfirmPasswordSecure.toggle()
                                    }) {
                                        Image(systemName: isConfirmPasswordSecure ? "eye.slash" : "eye")
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

                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Terms and Conditions
                            HStack(alignment: .top, spacing: 12) {
                                Button(action: {
                                    agreeToTerms.toggle()
                                }) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreeToTerms ? .green : .gray)
                                        .font(.title2)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("I agree to the Terms of Service and Privacy Policy")
                                        .font(.footnote)
                                        .foregroundColor(.primary)

                                    HStack(spacing: 16) {
                                        Button("Terms of Service") {
                                            showTermsAlert()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                        Button("Privacy Policy") {
                                            showPrivacyAlert()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)

                            // Register Button
                            Button(action: {
                                registerUser()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isLoading ? "Creating Account..." : "Create Account")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .disabled(isLoading || !isFormValid())
                            .opacity(isFormValid() ? 1.0 : 0.6)

                            // Login Link
                            HStack {
                                Text("Already have an account?")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                Button("Sign In") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            }
                            .padding(.top, 10)
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
        .sheet(isPresented: $isRegistered) {
            // Navigate to welcome screen after successful registration
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Welcome to Chatora!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your account has been created successfully")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Get Started") {
                    isRegistered = false
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }

    // MARK: - Helper Functions
    private func registerUser() {
        // Validate all fields
        guard isFormValid() else {
            showAlert(message: "Please fill in all fields correctly")
            return
        }

        isLoading = true

        // Simulate registration process (replace with actual authentication)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false

            // For demo purposes, accept any valid form
            isRegistered = true
        }
    }

    private func isFormValid() -> Bool {
        return !fullName.isEmpty &&
               isValidUsername(username) &&
               isValidEmail(email) &&
               isValidPassword(password) &&
               password == confirmPassword &&
               agreeToTerms
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegEx = "^[a-zA-Z0-9]{3,20}$"
        let usernamePred = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        return usernamePred.evaluate(with: username)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, contains uppercase, lowercase, and number
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }

    private func showTermsAlert() {
        showAlert(message: "Terms of Service: By using Chatora, you agree to our terms and conditions. This is a demo app.")
    }

    private func showPrivacyAlert() {
        showAlert(message: "Privacy Policy: We respect your privacy and protect your personal information. This is a demo app.")
    }
}



#Preview {
    RegisterView()
}