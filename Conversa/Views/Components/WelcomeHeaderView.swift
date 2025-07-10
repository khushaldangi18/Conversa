//
//  WelcomeHeaderView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct WelcomeHeaderView: View {
    let userName: String?
    let userEmail: String?
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Welcome to Conversa!")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let userName = userName, !userName.isEmpty {
                Text("Hello, \(userName)!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if let userEmail = userEmail {
                Text("Hello, \(userEmail)!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 2){
                Text("Your account has been created successfully")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
        }
        .padding(.top, 40)
    }
}

#Preview {
    VStack {
        WelcomeHeaderView(userName: "John Doe", userEmail: "john@example.com")
        
//        Divider()
//            .padding()
//        
//        WelcomeHeaderView(userName: nil, userEmail: "jane@example.com")
//        
//        Divider()
//            .padding()
//        
//        WelcomeHeaderView(userName: "", userEmail: "test@example.com")
    }
}
