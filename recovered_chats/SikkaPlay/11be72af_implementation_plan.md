# Block User Feature Implementation Plan

This plan details the end-to-end implementation of the Block User functionality, encompassing database changes, backend logic, matchmaking constraints, and frontend UI updates.

## User Review Required

> [!IMPORTANT]  
> **Chat Deletion Logic**: Currently, the app deletes messages globally (for both users). To support "Delete chat history only for the current user", I will introduce a `HiddenChat` table. This will store a timestamp of when a user cleared a chat, and the server will only return messages created *after* that timestamp for that specific user. The other user's history will remain intact. Please confirm if this approach is acceptable.

> [!IMPORTANT]
> **Matchmaking Performance**: Checking block status during the matchmaking loop requires a quick database query before finalizing a match. To ensure this doesn't slow down matchmaking at scale, I will add composite indexes on the `BlockedUser` table.

## Open Questions
- Do you want the "Block" button to appear on the `PlaygroundProfileScreen` as a main button (like "Add Friend"), or hidden in a 3-dot menu at the top right? I plan to add it as a prominent red button at the bottom of the profile.

## Proposed Changes

### Database Updates

#### [MODIFY] `backend/prisma/schema.prisma`
- Add `BlockedUser` model to track who blocked whom.
- Add `HiddenChat` model to support per-user chat history deletion (storing the timestamp of deletion).
- Add relations to the `User` model (`blocksInitiated`, `blocksReceived`).

### Backend Core & APIs

#### [MODIFY] `backend/src/controllers/playground.controller.ts`
- **New Endpoints**: 
  - `POST /playground/block`: Create block record, delete friendship (if any), and emit a socket event to instantly close active chat.
  - `POST /playground/unblock`: Remove block record.
  - `GET /playground/blocked`: Return list of users blocked by the current user.
  - `POST /playground/chat/hide`: Record a timestamp in `HiddenChat` for a channel to hide older messages for the current user.
- **Middleware/Security**: 
  - `sendPlaygroundMessage`: Reject (403) if a block exists in either direction.
  - `sendFriendRequest`: Reject (403) if blocked.
  - `syncPlaygroundMessages`: Filter messages created before the `HiddenChat` timestamp. If the user is the blocker, optionally hide the entire chat or disable inputs based on the response flags.

#### [MODIFY] `backend/src/services/matchmaking.service.ts`
- Inside the worker loop, before locking two users for a match, query the `BlockedUser` table. If a block exists, skip the pairing and attempt to match them with the next person in the queue.

#### [MODIFY] `backend/src/index.ts`
- Add a new socket event `user_blocked` to forcefully notify clients if they are blocked mid-conversation, ensuring the UI locks down instantly.

### Frontend UI & Logic

#### [MODIFY] `lib/features/playground/screens/playground_profile_screen.dart`
- Add a "BLOCK" button to the profile screen.
- Implement the confirmation dialog ("Blocked users won't be able to message you...").
- Upon confirmation, call the block API and immediately exit the profile screen.

#### [MODIFY] `lib/features/playground/screens/playground_studio_screen.dart`
- During `_loadChatHistory`, parse the `isBlocked` flags from the API response.
- **UI Lockdown**: If blocked (by either side), disable the text input, send button, game buttons, and attachment options.
- Intercept any local attempts to send messages/signals and show a Snackbar: "You can't send messages because this user is unavailable."
- Listen for the `user_blocked` socket event to apply the lockdown immediately if a block happens while the screen is open.

#### [MODIFY] `lib/features/playground/screens/playground_friends_screen.dart` (Chats Tab)
- Add a "Settings" gear icon in the `AppBar` at the top right (next to search).
- Tapping the icon navigates to the new Blocked Users settings page.

#### [NEW] `lib/features/playground/screens/playground_blocked_users_screen.dart`
- A dedicated settings screen listing all blocked users.
- Displays User Profile Picture, Name, and Date Blocked.
- Implements two actions per user:
  1. **Unblock**: Shows confirmation dialog, then calls unblock API.
  2. **Delete Chat**: Shows confirmation dialog, then calls the hide chat API to clear the local history without affecting the other user.

## Verification Plan

### Automated Tests
- Run `npx prisma db push` to verify schema changes.
- Ensure backend compiles with new endpoints.

### Manual Verification
- Log in as User A and User B.
- **Block Flow**: User A blocks User B. Verify friendship is removed. User A can no longer see the chat.
- **Lockdown Flow**: User B attempts to message User A. Verify UI blocks the input. If bypassed via API, verify the server returns 403.
- **Matchmaking Flow**: Verify User A and User B will never pair in random matchmaking.
- **Unblock Flow**: User A goes to Settings -> Blocked Users, unblocks User B. Verify they can now send friend requests again.
- **Delete Chat Flow**: User A clicks "Delete Chat" on the blocked screen. Verify User A's history is wiped, while User B's remains intact.
