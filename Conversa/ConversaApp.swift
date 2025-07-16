import SwiftUI
import Firebase
import FirebaseAuth

@main
struct ConversaApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.userIsLoggedIn {
                ContentView()
                    .environmentObject(appState)
                    .onAppear {
                        // Disable swipe-back to login after authentication
                        UINavigationBar.setAnimationsEnabled(false)
                    }
            } else {
                AuthView()
                    .environmentObject(appState)
            }
        }
    }
}
