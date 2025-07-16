# Firebase Database Structure

## Firestore Collections

### users
- Document ID: `{uid}` (Firebase Auth UID)
  - `email`: String
  - `fullName`: String
  - `username`: String (indexed for search, stored lowercase)
  - `photoURL`: String
  - `createdAt`: Timestamp
  - `lastActive`: Timestamp
  - `fcmToken`: String (for push notifications)
  - `blockedUsers`: Array<String> (UIDs of blocked users)
  - `blockedBy`: Array<String> (UIDs of users who blocked this user)
  - `statusRef`: String (reference to Realtime Database path)

### chats
- Document ID: Auto-generated
  - `participants`: Array<String> (UIDs of participants)
  - `participantUsernames`: Array<String> (for easier display)
  - `createdAt`: Timestamp
  - `lastMessage`: Map
    - `text`: String
    - `senderId`: String
    - `timestamp`: Timestamp
    - `type`: String (text/image/audio)
  - `lastMessageRead`: Map<String, Boolean> (UID -> read status)
  - `clearedBy`: Map<String, Timestamp> (UID -> when chat was cleared)

### messages
- Document ID: Auto-generated
  - `chatId`: String (reference to parent chat)
  - `senderId`: String (UID of sender)
  - `text`: String (optional)
  - `mediaURL`: String (optional, for images/audio)
  - `mediaType`: String (image/audio)
  - `timestamp`: Timestamp
  - `readBy`: Array<String> (UIDs of users who read)
  - `deliveredTo`: Array<String> (UIDs of users who received)
  - `deleted`: Boolean (default: false)
  - `deletedFor`: Array<String> (UIDs of users who deleted for themselves)
  - `deletedAt`: Timestamp (when message was deleted)

### notifications
- Document ID: Auto-generated
  - `recipientId`: String (UID of recipient)
  - `senderId`: String (UID of sender)
  - `chatId`: String (reference to chat)
  - `messageId`: String (reference to message)
  - `type`: String (new_message/new_chat)
  - `title`: String
  - `body`: String
  - `timestamp`: Timestamp
  - `read`: Boolean (default: false)
  - `delivered`: Boolean (default: false)

## Storage Structure

### /profile_images/{uid}.jpg
- User profile pictures

### /chat_media/{chatId}/{messageId}_{timestamp}.{extension}
- Shared images and audio files

## Realtime Database Paths

### /presence/{uid}
- `state`: String (online/offline/away)
- `last_changed`: ServerValue.TIMESTAMP
- `last_seen`: ServerValue.TIMESTAMP

### /typing/{chatId}/{uid}
- `isTyping`: Boolean
- `timestamp`: ServerValue.TIMESTAMP

### /message_status/{chatId}/{messageId}
- `delivered`: Array<String> (UIDs who received)
- `read`: Array<String> (UIDs who read)
- `timestamp`: ServerValue.TIMESTAMP

### /active_chats/{uid}/{chatId}
- `timestamp`: ServerValue.TIMESTAMP (for quick chat list access)
- `unreadCount`: Number

### /notifications_queue/{uid}
- `{notificationId}`: Map
  - `type`: String
  - `chatId`: String
  - `senderId`: String
  - `timestamp`: ServerValue.TIMESTAMP

## Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data and search others
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat access for participants only
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.participants;
    }
    
    // Messages within chats
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Notifications for recipient only
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.recipientId;
    }
  }
}
```

### Realtime Database Rules
```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": true,
        ".write": "$uid === auth.uid"
      }
    },
    "typing": {
      "$chatId": {
        "$uid": {
          ".read": true,
          ".write": "$uid === auth.uid"
        }
      }
    },
    "message_status": {
      "$chatId": {
        "$messageId": {
          ".read": true,
          ".write": "auth != null"
        }
      }
    },
    "active_chats": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "notifications_queue": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

## Implementation Features

### ✅ Real-time Messages
- Firestore real-time listeners on `/messages/{chatId}/messages`
- Automatic UI updates when new messages arrive

### ✅ New Chat Notifications  
- FCM push notifications via Cloud Functions
- Local notifications stored in `/notifications` collection

### ✅ Delete Older Messages
- Batch delete operations in Firestore
- Auto-cleanup Cloud Function for messages older than X days

### ✅ Chat Clear
- Update `clearedBy` field in chat document
- Filter messages by `timestamp > clearedBy[userId]`

### ✅ Block/Unblock Users
- `blockedUsers` array in user document
- `blockedBy` array for reverse lookup
- Filter blocked users from search and chats

### ✅ Message Seen Status
- Real-time updates via `/message_status/{chatId}/{messageId}`
- `readBy` array in message document for persistence

### ✅ Last Online Status
- Real-time presence system via `/presence/{uid}`
- Automatic online/offline detection
- `last_seen` timestamp for "last seen" feature

## Cloud Functions (Optional)
- **onMessageCreate**: Send push notifications
- **onUserPresence**: Update last seen timestamp
- **cleanupOldMessages**: Delete messages older than 30 days
- **updateChatLastMessage**: Update chat metadata on new message
