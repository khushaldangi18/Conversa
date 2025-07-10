# Firestore Database Structure

## Collections

### users
- Document ID: `{uid}` (Firebase Auth UID)
  - `email`: String
  - `fullName`: String
  - `username`: String (indexed for search)
  - `photoURL`: String
  - `createdAt`: Timestamp
  - `lastActive`: Timestamp
  - `fcmToken`: String (for notifications)
  - `blockedUsers`: Array<String> (UIDs of blocked users)
  - `status`: String (online/offline/away)

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

### messages
- Document ID: Auto-generated
  - `chatId`: String (reference to parent chat)
  - `senderId`: String (UID of sender)
  - `text`: String (optional)
  - `mediaURL`: String (optional, for images/audio)
  - `mediaType`: String (image/audio)
  - `timestamp`: Timestamp
  - `readBy`: Array<String> (UIDs of users who read)
  - `deleted`: Boolean (default: false)
  - `deletedFor`: Array<String> (UIDs of users who deleted for themselves)

## Storage Structure

### /profile_images/{uid}.jpg
- User profile pictures

### /chat_media/{chatId}/{messageId}_{timestamp}.{extension}
- Shared images and audio files