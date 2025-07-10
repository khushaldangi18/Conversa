//
//  User.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import Foundation
import FirebaseAuth

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let dateCreated: Date
    
    init(id: String, email: String, fullName: String, dateCreated: Date = Date()) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.dateCreated = dateCreated
    }
    
    // Convenience initializer from Firebase User
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.fullName = firebaseUser.displayName ?? ""
        self.dateCreated = firebaseUser.metadata.creationDate ?? Date()
    }
}

// MARK: - User Extensions
extension User {
    var displayName: String {
        return fullName.isEmpty ? email : fullName
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}

// MARK: - Sample Data for Previews
extension User {
    static let sampleUser = User(
        id: "sample-id",
        email: "john.doe@example.com",
        fullName: "John Doe"
    )
    
    static let sampleUsers = [
        User(id: "1", email: "alice@example.com", fullName: "Alice Johnson"),
        User(id: "2", email: "bob@example.com", fullName: "Bob Smith"),
        User(id: "3", email: "charlie@example.com", fullName: "Charlie Brown")
    ]
}
