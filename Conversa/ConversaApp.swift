import SwiftUI
import Firebase
import FirebaseAuth

@main
struct ConversaApp: App {
    @State private var userIsLoggedIn = false
    
    init() {
        FirebaseApp.configure()
        checkUserAuth()
    }
    
    func checkUserAuth() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.userIsLoggedIn = user != nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if userIsLoggedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}
