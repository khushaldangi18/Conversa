import Foundation
import Firebase
import FirebaseDatabase

class PresenceManager {
    static let shared = PresenceManager()
    
    private var ref: DatabaseReference
    private var userStatusRef: DatabaseReference?
    private var connectedRef: DatabaseReference
    
    private init() {
        ref = Database.database().reference()
        connectedRef = Database.database().reference(withPath: ".info/connected")
    }
    
    func setupPresence(for userId: String) {
        userStatusRef = ref.child("presence").child(userId)
        
        // Monitor connection state
        connectedRef.observe(.value) { [weak self] snapshot in
            guard let self = self,
                  let connected = snapshot.value as? Bool,
                  connected,
                  let userStatusRef = self.userStatusRef else {
                return
            }
            
            // When we disconnect, remove this device
            let onDisconnectRef = userStatusRef
            onDisconnectRef.onDisconnectUpdateChildValues([
                "state": "offline",
                "last_seen": ServerValue.timestamp(),
                "last_changed": ServerValue.timestamp()
            ])
            
            // Set online status
            let status: [String: Any] = [
                "state": "online",
                "last_seen": ServerValue.timestamp(),
                "last_changed": ServerValue.timestamp()
            ]
            
            userStatusRef.updateChildValues(status)
        }
    }
    
    func setStatus(_ status: String, for userId: String) {
        let userStatusRef = ref.child("presence").child(userId)
        let status: [String: Any] = [
            "state": status,
            "last_changed": ServerValue.timestamp()
        ]
        userStatusRef.updateChildValues(status)
    }
    
    func observeUserStatus(for userId: String, completion: @escaping (String, Date?) -> Void) -> DatabaseHandle {
        let userStatusRef = ref.child("presence").child(userId)
        return userStatusRef.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion("offline", nil)
                return
            }
            
            let state = value["state"] as? String ?? "offline"
            
            var lastSeen: Date? = nil
            if let lastSeenTimestamp = value["last_seen"] as? Double {
                lastSeen = Date(timeIntervalSince1970: lastSeenTimestamp / 1000)
            }
            
            completion(state, lastSeen)
        }
    }
    
    func removeObserver(for userId: String, handle: DatabaseHandle) {
        let userStatusRef = ref.child("presence").child(userId)
        userStatusRef.removeObserver(withHandle: handle)
    }
    
    func cleanupPresence() {
        if let userStatusRef = userStatusRef {
            userStatusRef.removeAllObservers()
        }
    }
}