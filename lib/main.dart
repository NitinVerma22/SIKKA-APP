import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/theme/app_theme.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/routes/app_router.dart';
import 'package:sikkaplay/features/playground/screens/playground_studio_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<String?> _checkDeviceSafety() async {
  if (kDebugMode) {
    // Skip safety checks in debug mode for development and emulator testing
    return null;
  }
  try {
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isDevelopmentMode = await SafeDevice.isDevelopmentModeEnable;

    if (isJailBroken) {
      return "This device is rooted/jailbroken. SikkaPlay cannot run on rooted devices for security reasons.";
    } else if (!isRealDevice) {
      return "SikkaPlay cannot run on an emulator.";
    } else if (isDevelopmentMode) {
      return "Developer Mode is enabled. Please disable Developer Options in your settings to use SikkaPlay.";
    }
  } catch (e) {
    print("Error during device safety check: $e");
  }
  return null;
}
final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  _handleNotificationAction(notificationResponse);
}

@pragma('vm:entry-point')
Future<void> _handleNotificationAction(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final String? payloadStr = response.payload;
  if (payloadStr == null || payloadStr.isEmpty) return;

  try {
    final Map<String, dynamic> data = json.decode(payloadStr);
    final String channelName = data['channelName'] ?? '';
    final String partnerId = data['partnerId'] ?? '';
    final String partnerName = data['partnerName'] ?? 'SikkaPlay Friend';
    final String partnerAvatar = data['senderAvatar'] ?? '';

    if (response.actionId == 'mute_action') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mute_$partnerId', DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch);
      debugPrint('Muted sender $partnerId for 5 minutes.');
      return;
    } else if (response.actionId == 'reply_action') {
      final String? replyText = response.input;
      if (replyText != null && replyText.trim().isNotEmpty) {
        final PlaygroundService service = PlaygroundService();
        await service.sendPlaygroundMessage(channelName, replyText, recipientId: partnerId);
        debugPrint('Successfully sent notification reply to $partnerId');
      }
      return;
    }

    // Standard tap: Open the chat room
    if (channelName.isNotEmpty && partnerId.isNotEmpty) {
      globalPushChatScreenWithRetry(channelName, partnerId, partnerName, 15, partnerAvatar: partnerAvatar);
    }
  } catch (e) {
    debugPrint('Error handling notification tap: $e');
  }
}

void globalPushChatScreenWithRetry(String channelName, String partnerId, String partnerName, int retries, {String? partnerAvatar}) {
  if (rootNavigatorKey.currentContext == null) {
    if (retries > 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        globalPushChatScreenWithRetry(channelName, partnerId, partnerName, retries - 1, partnerAvatar: partnerAvatar);
      });
    }
    return;
  }
  
  final String effectiveChannel = partnerId.trim().isNotEmpty ? 'friend-chat-${partnerId.trim()}' : channelName;
  
  rootNavigatorKey.currentContext?.push('/playground/studio', extra: {
    'channelName': effectiveChannel,
    'agoraToken': effectiveChannel,
    'partnerId': partnerId,
    'partnerName': partnerName,
    'partnerUsername': '',
    'partnerAvatar': partnerAvatar ?? '',
  });
}

Future<String?> _downloadAndSaveFile(String? url, String fileName) async {
  if (url == null || url.trim().isEmpty) return null;
  try {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }
  } catch (e) {
    print('Error downloading image for notification: $e');
  }
  return null;
}

Future<void> _showLocalNotification(RemoteMessage message) async {

  final String? senderId = message.data['senderId'];
  if (senderId != null && senderId.isNotEmpty) {
    // 1. Suppress if muted
    final prefs = await SharedPreferences.getInstance();
    final muteExpiryMs = prefs.getInt('mute_$senderId');
    if (muteExpiryMs != null && DateTime.now().millisecondsSinceEpoch < muteExpiryMs) {
      debugPrint('Muted sender notification suppressed: $senderId');
      return;
    }
    
    // 2. Suppress if this is my own message (testing on same device with shared FCM token)
    if (PlaygroundStudioScreen.currentUserId == senderId) {
      debugPrint('Self-message notification suppressed (same device testing)');
      return;
    }

    // 3. Suppress if we are currently chatting with this user
    final String activeChannel = PlaygroundStudioScreen.activeChannelName ?? '';
    if (activeChannel.contains(senderId)) {
      debugPrint('Active chat notification suppressed: $senderId');
      return;
    }
  }

  final notification = message.notification;
  final String title = notification?.title ?? message.data['title'] ?? 'SikkaPlay';
  final String body = notification?.body ?? message.data['body'] ?? '';
  
  if (title.isEmpty && body.isEmpty) return;

  final String? imageUrl = notification?.android?.imageUrl ?? message.data['bannerUrl'] ?? message.data['imageUrl'];
  String? bigPicturePath;

  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    final String hash = (message.hashCode.abs() % 100000).toString();
    bigPicturePath = await _downloadAndSaveFile(imageUrl, 'notif_big_picture_$hash.jpg');
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'sikkaplay_high_channel_v2',
    'SikkaPlay Notifications',
    channelDescription: 'Main notification channel for SikkaPlay',
    importance: Importance.max,
    priority: Priority.high,
    color: const Color(0xFF7C3AED), // App brand theme color (Purple)
    icon: 'ic_launcher',
    largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
    styleInformation: bigPicturePath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
            contentTitle: title,
            summaryText: body,
          )
        : null,
    playSound: true,
    enableVibration: true,
  );
  
  final details = NotificationDetails(android: androidDetails);
  
  final payloadData = json.encode({
    'channelName': message.data['channelName'] ?? '',
    'partnerId': senderId ?? '',
    'partnerName': title,
  });

  await localNotifications.show(
    id: (message.hashCode.abs() % 100000),
    title: title,
    body: body,
    notificationDetails: details,
    payload: payloadData,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  try {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await localNotifications.initialize(settings: initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sikkaplay_high_channel_v2',
      'SikkaPlay Notifications',
      description: 'Main notification channel for SikkaPlay',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);

    await _showLocalNotification(message);
  } catch (e) {
    debugPrint('Error handling background FCM message: $e');
  }
}

Future<void> _initializeServices() async {
  try {
    tz.initializeTimeZones();

    // Pass all Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Initialize Google Mobile Ads SDK asynchronously
    unawaited(AdService.instance.initialize());
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Configure Android Notification Channel  // Create high importance channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sikkaplay_high_channel_v2_v2',
      'SikkaPlay Notifications',
      description: 'Main notification channel for SikkaPlay',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    await androidImplementation?.createNotificationChannel(channel);
    
    // Request permission safely (requires active Activity attached)
    await androidImplementation?.requestNotificationsPermission();
    await FirebaseMessaging.instance.requestPermission();

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Listen for FCM token refresh and sync with backend
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      AuthService().updateFcmTokenOnServer(newToken);
    });
  } catch (e) {
    debugPrint('Error initializing background services: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await _initializeServices();
  
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  tz.initializeTimeZones();

  String? safetyError = await _checkDeviceSafety();
  if (safetyError != null) {
    runApp(UnsafeDeviceApp(errorMessage: safetyError));
    return;
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  unawaited(AdService.instance.initialize());

  runApp(const ProviderScope(child: SikkaPlayApp()));
}

class SikkaPlayApp extends ConsumerStatefulWidget {
  const SikkaPlayApp({super.key});

  @override
  ConsumerState<SikkaPlayApp> createState() => _SikkaPlayAppState();
}

class _SikkaPlayAppState extends ConsumerState<SikkaPlayApp> with WidgetsBindingObserver {

  // ── FIX 9: Offline Detection ─────────────────────────────────────────────
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;
  // ────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ── FIX 9: Listen for connectivity changes ───────────────────────────
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final offline = results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
        if (offline != _isOffline) {
          setState(() => _isOffline = offline);
        }
      },
    );
    // Immediately check current connectivity status
    Connectivity().checkConnectivity().then((results) {
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
    // ────────────────────────────────────────────────────────────────────
    _requestPermissions();
    _syncFcmTokenOnStartup();
    _initFirebasePushListeners();
  }

  Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          await Permission.photos.request();
        } else {
          await Permission.storage.request();
        }
      } else {
        await Permission.photos.request();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _initFirebasePushListeners() async {
    try {
      // 1. App killed state - opened via notification tap
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        _handleFirebaseMessageTap(message);
      }

      // 2. App background state - opened via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleFirebaseMessageTap(message);
      });
    } catch (e) {
      debugPrint('Error init push listeners: $e');
    }
  }

  void _handleFirebaseMessageTap(RemoteMessage message) {
    // When backend sends FCM data payload, it comes in message.data
    final channelName = message.data['channelName'] ?? '';
    final partnerId = message.data['senderId'] ?? message.data['partnerId'] ?? '';
    final partnerName = message.data['senderName'] ?? message.data['partnerName'] ?? 'SikkaPlay Friend';
    final partnerAvatar = message.data['senderAvatar'] ?? '';

    if (channelName.isNotEmpty && partnerId.isNotEmpty) {
      _pushChatScreenWithRetry(channelName, partnerId, partnerName, 10, partnerAvatar: partnerAvatar);
    }
  }

  void _pushChatScreenWithRetry(String channelName, String partnerId, String partnerName, int retries, {String? partnerAvatar}) {
    if (rootNavigatorKey.currentContext == null) {
      if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _pushChatScreenWithRetry(channelName, partnerId, partnerName, retries - 1, partnerAvatar: partnerAvatar);
        });
      }
      return;
    }
    
    final String effectiveChannel = partnerId.trim().isNotEmpty ? 'friend-chat-${partnerId.trim()}' : channelName;

    rootNavigatorKey.currentContext?.push('/playground/studio', extra: {
      'channelName': effectiveChannel,
      'agoraToken': effectiveChannel,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerUsername': '',
      'partnerAvatar': partnerAvatar ?? '',
    });
  }



  Future<void> _syncFcmTokenOnStartup() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final AuthService auth = AuthService();
        await auth.updateFcmTokenOnServer(token);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token on startup: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // FIX 9: cleanup listener
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background, schedule notifications
      _scheduleBackgroundNotifications();
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground, cancel pending notifications
      localNotifications.cancelAll();
    }
  }

  Future<void> _scheduleBackgroundNotifications() async {
    const androidDetails = AndroidNotificationDetails(
      'engagement_channel',
      'Engagement Reminders',
      channelDescription: 'Reminders to come back and play',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF7C3AED),
      icon: 'ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 3));
      
      await localNotifications.zonedSchedule(
        id: 2,
        title: '🥺 Sikka aapka wait kar raha hai!',
        body: 'Aaiye aur apna daily task poora karein 🔥',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('Scheduled background notification for: $scheduledTime');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SikkaPlay',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      // ── FIX 9: Offline overlay banner via builder ──────────────────────
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15,
            ),
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              // Show offline banner only when connectivity is lost
              if (_isOffline)
                Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class UnsafeDeviceApp extends StatelessWidget {
  final String errorMessage;

  const UnsafeDeviceApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F0F16),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F16), Color(0xFF1E1E2F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF4D4D).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Color(0xFFFF4D4D),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Security Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC0C0CF),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        exit(0);
                      },
                      child: const Text(
                        'Exit App',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
