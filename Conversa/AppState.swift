import SwiftUI
import Firebase

class AppState: ObservableObject {
    @Published var userIsLoggedIn: Bool = false
    
    init() {
        // Set initial state based on Firebase auth
        userIsLoggedIn = FirebaseManager.shared.auth.currentUser != nil
        
        // Listen for auth state changes
        FirebaseManager.shared.auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.userIsLoggedIn = user != nil
            }
        }
    }
}