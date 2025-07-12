//
//  ContentView.swift
//  Conversa
//
//  Created by FCP 21 on 07/07/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showingLoginView = false
    
    var body: some View {
        
        
        TabView {
            
            MainMessageView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
//            Text("Search Screen")
//                .tabItem {
//                    Image(systemName: "magnifyingglass")
//                    Text("Search")
//                }
            
            Text("Profile View")
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
