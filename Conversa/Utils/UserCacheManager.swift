import Foundation
import FirebaseFirestore

class UserCacheManager: ObservableObject {
    static let shared = UserCacheManager()
    
    private var userCache: [String: User] = [:]
    private var loadingUsers: Set<String> = []
    
    private init() {}
    
    func getUser(uid: String, completion: @escaping (User?) -> Void) {
        // Return cached user if available
        if let cachedUser = userCache[uid] {
            completion(cachedUser)
            return
        }
        
        // Avoid duplicate requests
        if loadingUsers.contains(uid) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.getUser(uid: uid, completion: completion)
            }
            return
        }
        
        loadingUsers.insert(uid)
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            self.loadingUsers.remove(uid)
            
            if let data = snapshot?.data() {
                let user = User(
                    uid: uid,
                    email: data["email"] as? String ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    photoURL: data["photoURL"] as? String ?? ""
                )
                self.userCache[uid] = user
                completion(user)
            } else {
                completion(nil)
            }
        }
    }
    
    func clearCache() {
        userCache.removeAll()
    }
}