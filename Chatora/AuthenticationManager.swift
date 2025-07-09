//
//  AuthenticationManager.swift
//  Chatora
//
//  Created by FCP 21 on 08/07/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseAuth
import Firebase

// MARK: - User Model
struct ChatUser {
    let uid: String
    let email: String
    let fullName: String
    let username: String
}

class AuthenticationManager: ObservableObject {
    @Published var user: ChatUser?
    @Published var isAuthenticated = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.user = ChatUser(
                        uid: user.uid,
                        email: user.email ?? "",
                        fullName: user.displayName ?? "",
                        username: user.displayName ?? ""
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String, username: String) async throws -> ChatUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update user profile with display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()

            // Store additional user data (optional - for future Firestore integration)
            await storeUserData(uid: result.user.uid, email: email, fullName: fullName, username: username)

            let chatUser = ChatUser(
                uid: result.user.uid,
                email: email,
                fullName: fullName,
                username: username
            )

            return chatUser
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> ChatUser {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)

            let chatUser = ChatUser(
                uid: result.user.uid,
                email: result.user.email ?? email,
                fullName: result.user.displayName ?? "",
                username: result.user.displayName ?? ""
            )

            return chatUser
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.from(error)
        }
    }
    
    // MARK: - Store User Data
    private func storeUserData(uid: String, email: String, fullName: String, username: String) async {
        // This is where you would store additional user data in Firestore
        // For now, we'll just print the data
        print("Storing user data for UID: \(uid)")
        print("Email: \(email), Full Name: \(fullName), Username: \(username)")
        
        // TODO: Implement Firestore storage when needed
        // let db = Firestore.firestore()
        // let userData: [String: Any] = [
        //     "email": email,
        //     "fullName": fullName,
        //     "username": username,
        //     "createdAt": Timestamp()
        // ]
        // try await db.collection("users").document(uid).setData(userData)
    }
}

// MARK: - Auth Error Handling
enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email address."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please choose a stronger password."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: Error) -> AuthError {
        guard let authError = error as NSError? else {
            return .unknown(error.localizedDescription)
        }

        switch authError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        default:
            return .unknown(authError.localizedDescription)
        }
    }
}
