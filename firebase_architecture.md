# Firebase Architecture for Chat App

## Firestore Collections
```
/users/{uid}
  - email, username, profileImage
  - blockedUsers: [uid1, uid2]
  - fcmToken (for notifications)

/chats/{chatId}
  - participants: [uid1, uid2]
  - lastMessage: {text, timestamp, senderId}
  - createdAt, updatedAt

/messages/{chatId}/messages/{messageId}
  - text, senderId, timestamp
  - readBy: [uid1, uid2]
  - deleted: boolean
```

## Realtime Database Paths
```
/presence/{uid}
  - state: "online"/"offline"
  - last_changed: timestamp

/typing/{chatId}/{uid}
  - isTyping: true/false
  - timestamp

/message_status/{chatId}/{messageId}
  - delivered: [uid1, uid2]
  - read: [uid1, uid2]