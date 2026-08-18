# SikkaPlay Chat System Architecture Review

This document outlines the end-to-end architecture, connection flow, and state management of the SikkaPlay real-time chat and game synchronization system.

## 1. Technology Stack
- **Backend**: Node.js, Express.js, Socket.io (Real-time engine), Prisma (PostgreSQL database), Firebase Admin SDK (Push Notifications).
- **Frontend**: Flutter, `socket_io_client` (WebSockets), `firebase_messaging` (FCM), `flutter_local_notifications`.

---

## 2. Core Connection Flow & Room Management

### 2.1 Initialization
When a user opens the chat screen (`PlaygroundStudioScreen`):
1. **HTTP History Sync**: The frontend makes a REST API call (`/api/playground/chat/sync`) to fetch the last 24 hours of message history and the `currentUserId`.
2. **Socket Handshake**: The frontend initializes a dedicated, authenticated Socket.io connection using `enableForceNew: true` (ensuring it doesn't collide with any global app sockets).

### 2.2 Room Normalization (The "Canonical" Channel)
To ensure both User A and User B can communicate, they must exist in the exact same virtual room.
- The system takes both `User A ID` and `User B ID`, sorts them alphabetically, and generates a canonical room name: `private-chat-{id1}-{id2}`.
- The frontend emits a `join_room` event to the backend, and the backend adds the user's socket to this specific room.

---

## 3. Message Lifecycle (A → B)

When User A sends a message to User B, the system employs a **Hybrid HTTP + WebSocket Architecture**:

1. **Persistence First (HTTP POST)**: 
   - User A sends the message text to the REST API (`/api/playground/chat/send`).
   - The backend validates the request and immediately saves the message to the PostgreSQL database via Prisma (`PlaygroundMessage` table).
2. **Real-Time Broadcast (Socket.io)**: 
   - After saving, the backend uses `io.to('private-chat-{id1}-{id2}').emit('new_message', msg)` to broadcast the message to the room.
   - User B's socket listener instantly catches `new_message` and appends it to the Flutter UI without requiring a page refresh.
3. **Read Receipts (Blue Ticks)**:
   - Once User B's screen renders the message, it emits a `mark_seen` socket event back to the server.
   - The server updates the DB `isSeen = true` and emits `message_seen` to User A, turning their grey ticks into blue ticks.

---

## 4. Presence & Push Notification Engine

The system intelligently routes notifications based on the recipient's exact screen state to avoid spam.

1. **Heartbeat Tracking**: 
   - Every 10 seconds, the frontend pings the backend (`updateActiveChannel`) to declare which chat room the user is currently looking at. 
   - The backend stores this in an in-memory Map: `userActiveChannelCache`.
2. **Decision Matrix**:
   - When User A sends a message to User B, the backend checks `userActiveChannelCache.get(UserB)`.
   - **If MATCH (User B is in chat)**: The backend does *nothing*. The socket handles delivery.
   - **If NO MATCH (User B is offline or on home screen)**: The backend invokes Firebase Admin to send an FCM Push Notification to User B's device token.

---

## 5. Tic-Tac-Toe Game Synchronization

Unlike text messages (which need database persistence for history), game moves require ultra-low latency and do not need to be saved in the database permanently.

- **Direct Socket Emissions**: When User A taps a grid square, the frontend completely bypasses the HTTP API and directly emits `game_move` over the Socket.io connection.
- **Relay**: The backend simply relays this payload to the opponent in the `private-chat` room.
- **Result**: Sub-100ms latency synchronization, preventing race conditions and database bloat.

---

## 6. Current Bugs & Proposed Fixes

Here is the technical breakdown of the two bugs currently being patched:

> [!WARNING]
> **Bug 1: Duplicate Message Rendering**
> **Cause**: The frontend was joining both the canonical `private-chat` room AND a fallback `friend-chat` room. The backend was emitting to both rooms as a safety measure. The frontend received both events, and because the Flutter list insertion lacked deduplication, it rendered twice.
> **Fix**: Implement an idempotent `id` check on the frontend (`_messages.any((m) => m.id == msgId)`) before appending to the state.

> [!WARNING]
> **Bug 2: Unwanted Push Notifications**
> **Cause A (Same Device Testing)**: When testing two accounts on the same physical device, they share the exact same FCM device token. When User A sends a message, the server pushes to User B's token (which is the current device), causing User A to see a notification for their own message.
> **Cause B (Foreground Catch-all)**: The Flutter `FirebaseMessaging.onMessage.listen` handler in `main.dart` was unconditionally displaying a local SnackBar for *all* incoming FCM messages, regardless of the active screen state.
> **Fix**: Add a context-aware suppression block in `main.dart` that intercepts the local notification if the FCM payload's `senderId` matches the currently logged-in user, or if the user is already on the chat screen with that sender.
