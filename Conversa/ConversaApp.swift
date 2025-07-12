import SwiftUI
import Firebase

@main
struct ConversaApp: App {
    init() {
        // Configure Firebase only once when the app starts
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}
