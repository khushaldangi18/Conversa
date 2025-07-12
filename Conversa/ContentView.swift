//
//  ContentView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainMessageView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView()
}
