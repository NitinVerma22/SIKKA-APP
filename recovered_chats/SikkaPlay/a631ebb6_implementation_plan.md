# Persist and Display Profile Avatars Globally

The user reported that the profile photo uploads successfully and shows on the profile page, but disappears when the app is restarted. Additionally, the avatar is not visible in other screens like Playground, Chat, Friends tab, and Search.

## Background Context
Currently, when a user uploads a profile photo:
1. The Flutter app compresses the image to a 512x512 JPEG with 80% quality.
2. It sends this as a Base64 string to the backend.
3. The backend saves the image to the local filesystem (`/public/uploads/avatars/`) and stores the absolute URL (e.g. `http://localhost:3000/...` or a Cloud Run URL) in the database.

Since the backend is running locally (or on ephemeral cloud instances), the saved file is wiped out on restart, or the IP address changes, causing the `avatarUrl` in the database to break. Furthermore, the frontend only expects `avatarUrl` to be an HTTP link or an asset path.

## Proposed Changes

We will fix this by persisting the Base64 image directly into the database, which completely avoids filesystem wipes and broken URLs.

### 1. Backend Update (`user.controller.ts`)
- Modify `updateAvatar` to bypass writing to the filesystem.
- Store the compressed `imageBase64` string directly into the `avatarUrl` column in the PostgreSQL database.
- Since the image is pre-compressed in Flutter, the Base64 string will be tiny (approx 50-100KB) and perfectly suited for the `TEXT` column.

### 2. Frontend Updates
Update the avatar rendering logic across the app to support Base64 images.

#### [MODIFY] [profile_screen.dart](file:///e:/development/SikkaPlay/lib/features/profile/screens/profile_screen.dart)
- Update the avatar display widget to check `userData['avatarUrl'].toString().startsWith('data:image')`.
- If true, use `Image.memory(base64Decode(...))` to render it.

#### [MODIFY] [playground_friends_screen.dart](file:///e:/development/SikkaPlay/lib/features/playground/screens/playground_friends_screen.dart)
- Update the `_buildAvatar` helper to support Base64 strings.

#### [MODIFY] [playground_lobby_screen.dart](file:///e:/development/SikkaPlay/lib/features/playground/screens/playground_lobby_screen.dart)
- Update the image rendering to support Base64 strings.

#### [MODIFY] [playground_profile_screen.dart](file:///e:/development/SikkaPlay/lib/features/playground/screens/playground_profile_screen.dart)
- Update the `_buildAvatar` helper to support Base64 strings.

#### [MODIFY] [playground_search_screen.dart](file:///e:/development/SikkaPlay/lib/features/playground/screens/playground_search_screen.dart)
- Update the avatar display widget to support Base64 strings.

## User Review Required
> [!IMPORTANT]
> The database column `avatarUrl` is a `String`. Storing a Base64 string will work seamlessly. Please approve this plan so I can implement the Base64 rendering logic across all screens and fix the backend!
