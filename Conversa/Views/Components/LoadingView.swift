//
//  LoadingView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo with pulse animation
            Image(systemName: "message.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)

            // App Name
            Text("Conversa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Loading indicator with text
            VStack(spacing: 15) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)

                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            print("📱 LoadingView: Loading screen appeared")
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}
