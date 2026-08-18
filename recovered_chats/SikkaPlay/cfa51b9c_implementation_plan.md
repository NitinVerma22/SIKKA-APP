# Fix SikkaPlay "Connect with Stranger" Matchmaking

Fix the issue where matchmaking stays stuck in an infinite "matching..." state without ever connecting users, and ensure partner profile details load correctly when a match is established.

## User Review Required

> [!IMPORTANT]
> This plan modifies both the Flutter frontend navigation (passing user gender to the matchmaking screen) and the Node.js/Socket.io backend (adding user ID tracking to socket sessions, cleaning up queues on disconnect, and enriching `match_found` events with database user profile metadata).

> [!NOTE]
> The legacy in-memory HTTP matchmaking endpoints (`/api/playground/matchmaking/join` and `/status`) in `playground.controller.ts` are dead code since the app uses real-time WebSockets and Redis. We will remove/clean up this unused in-memory queue to prevent architectural divergence.

## Proposed Changes

### Frontend (Flutter)

#### [MODIFY] [playground_lobby_screen.dart](file:///e:/development/SikkaPlay/lib/features/playground/screens/playground_lobby_screen.dart)
- Add a private state variable `String _gender = 'male';` to `_PlaygroundLobbyScreenState`.
- In `_loadLobbyData()`, extract and save the user's gender from the backend response: `_gender = res['gender'] ?? 'male';`.
- In `_buildConnectButton()`, pass the gender in the extra parameter when navigating:
  ```dart
  context.push('/playground/matchmaking', extra: {'gender': _gender});
  ```

---

### Backend (Node.js / Express / Socket.io)

#### [MODIFY] [index.ts](file:///e:/development/SikkaPlay/backend/src/index.ts)
- In the `matchmaking_search_start` socket listener, record `socket.data.userId = userId;` when a user starts searching.
- In the `disconnect` socket listener, if `socket.data.userId` is present, call `matchmakingService.handleDisconnect(socket.data.userId)` to immediately purge the disconnected user from Redis queues instead of waiting for the 30-second heartbeat timeout.

#### [MODIFY] [matchmaking.service.ts](file:///e:/development/SikkaPlay/backend/src/services/matchmaking.service.ts)
- Add `public async handleDisconnect(userId: string)` to immediately remove a user from Redis queues (`QUEUES[state.gender]`) and clean up their state if they disconnect while `SEARCHING` or `CHATTING`.
- In `createMatch(user1, user2)`, query Prisma (`prisma.user.findUnique`) for both users to fetch their real profile data (`name`, `username`, `avatarUrl`).
- Include `partnerName`, `partnerUsername`, and `partnerAvatar` in the `match_found` socket event emitted to both participants so the chat studio UI displays authentic user information instead of blanks.

#### [MODIFY] [playground.controller.ts](file:///e:/development/SikkaPlay/backend/src/controllers/playground.controller.ts)
- Clean up the legacy in-memory `matchmakingQueue` and `matchResults` arrays and streamline `joinMatchmaking` / `checkMatchmakingStatus` to avoid confusing dual-state matchmaking.

## Verification Plan

### Automated / Local Verification
- Run backend TypeScript compilation (`npx tsc --noEmit` or equivalent check in `backend`) to ensure no syntax or type errors in `index.ts`, `matchmaking.service.ts`, and `playground.controller.ts`.
- Check Flutter analysis (`flutter analyze` in the workspace root) to confirm no warnings or errors in `playground_lobby_screen.dart`.

### Manual Verification
1. Start the local backend server and check Redis connection logs.
2. Launch two instances of the SikkaPlay Flutter app (or test with simulated socket events).
3. Verify that clicking "CONNECT WITH STRANGER" passes the correct gender and puts the user into the proper Redis queue (`matchmaking:queue:male` or `female`).
4. Verify that two compatible searching users immediately receive the `match_found` event containing full partner metadata (`partnerName`, `partnerAvatar`).
5. Verify that disconnecting a searching user immediately removes their ID from Redis without leaving a ghost session behind.
