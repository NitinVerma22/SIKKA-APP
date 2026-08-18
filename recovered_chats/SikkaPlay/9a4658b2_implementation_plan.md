# Fix Push Notification Actions (Reply, Mute, Direct Chat Navigation)

## Goal Description
The push notification system currently has three critical issues:
1. **Reply Action Fails**: When the app is in the background, tapping "Reply" and typing a message doesn't actually send it. This is because background isolates require `WidgetsFlutterBinding.ensureInitialized()` before they can access things like `SharedPreferences` (which is needed to get the Auth Token for the backend).
2. **Mute Action Fails**: The "Mute" action saves the muted user to a memory map in the background isolate, which is not synced with the main app isolate, meaning the main app still shows notifications.
3. **Notification Tap on Cold Start**: Tapping a local notification when the app is completely closed (terminated) opens the Home screen instead of the direct chat room. This is because the app doesn't read the `getNotificationAppLaunchDetails()` on startup, and even if it did, the routing logic fires before the `GoRouter` is mounted.

## Proposed Changes

### 1. Fix Background Reply and Mute (`lib/main.dart`)
- **Initialize Flutter Bindings**: Add `WidgetsFlutterBinding.ensureInitialized();` at the beginning of `_handleNotificationAction`.
- **Persist Muted State**: Change `_mutedSenders` from a RAM dictionary to use `SharedPreferences`. Both `_handleNotificationAction` (Mute button) and `_showLocalNotification` (notification interceptor) will read/write from `SharedPreferences` using a key like `mute_{userId}`.

### 2. Fix Terminated State Notification Tap (`lib/main.dart`)
- **Read Initial Local Notification**: During app startup (`_initializeServices` or `initState`), add a check for `localNotifications.getNotificationAppLaunchDetails()`. If the app was launched via a local notification tap, parse the payload.
- **Robust Route Pushing (Retry Logic)**: Inside `_handleNotificationAction`, replace the fragile `addPostFrameCallback` with a robust global retry function (`globalPushChatScreenWithRetry`) that polls for `rootNavigatorKey.currentContext` to be non-null up to 10 times. This guarantees that whether the app is cold-starting or just resuming, it waits for the router to be fully initialized before pushing the user to `/playground/studio`.

## User Review Required
> [!IMPORTANT]
> These changes are isolated entirely to the Flutter app codebase (`main.dart`). After I implement these fixes, you **MUST** rebuild your Flutter app (generate a new APK/AppBundle) for the notification actions to work properly. No backend changes are required.

## Verification Plan
1. Completely close the app from recent apps.
2. Send a message from another device.
3. Tap the notification on the closed device. It should launch and go **directly** to the chat screen.
4. Try using the "Mute" action and confirm no more notifications trigger for that user for 5 minutes.
5. Try using the "Reply" action from the notification tray and confirm the message is successfully sent to the other user without fully opening the app.
