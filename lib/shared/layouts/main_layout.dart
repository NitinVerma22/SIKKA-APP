import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/routes/app_router.dart';
import 'package:sikkaplay/features/wallet/controllers/wallet_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/playground/screens/playground_studio_screen.dart';
import 'package:sikkaplay/core/config/app_config.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sikkaplay/core/services/socket_provider.dart';

final navigationHistoryProvider = StateProvider<List<int>>((ref) => [0]);

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  DateTime? _lastPressedAt;
  
  IO.Socket? _globalSocket;
  final PlaygroundService _service = PlaygroundService();
  final Map<String, String> _lastMsgTimes = {};
  
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initGlobalSocket();
    
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.contains(ConnectivityResult.none));
      }
    });
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final offline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != offline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _globalSocket?.disconnect();
    _globalSocket?.dispose();
    super.dispose();
  }

  Future<void> _initGlobalSocket() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    
    // Connect to WebSocket server using the base URL
    final wsUrl = AuthService.baseUrl.replaceAll('/api/auth', '');
    
    _globalSocket = IO.io(wsUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());

    // Expose socket via provider
    Future.microtask(() {
      ref.read(globalSocketProvider.notifier).state = _globalSocket;
    });

    _globalSocket?.connect();

    _globalSocket?.onConnect((_) {
      debugPrint('[Socket] Connected globally');
      final myUserId = ref.read(userProvider).userData?['id']?.toString() ?? '';
      if (myUserId.isNotEmpty) {
        debugPrint('[Socket] Joining room on connect: friend-chat-$myUserId');
        _globalSocket!.emit('join_room', 'friend-chat-$myUserId');
      }
      _fetchFriendsAndCheckMessages();
    });

    _globalSocket?.on('friends_update', (_) {
      _fetchFriendsAndCheckMessages();
    });

    _globalSocket?.on('new_message', (data) {
      _handleIncomingMessageSocket(data);
    });
  }

  Future<void> _fetchFriendsAndCheckMessages() async {
    if (!mounted) return;
    
    final res = await _service.getFriendsList();
    if (!mounted) return;

    if (res['success'] == true) {
      final friendsList = res['friends'] as List? ?? [];
      final pendingRequests = res['pendingRequests'] as List? ?? [];

      ref.read(globalFriendsListProvider.notifier).state = friendsList;
      ref.read(globalPendingRequestsProvider.notifier).state = pendingRequests;

      for (final friend in friendsList) {
        final friendId = friend['id']?.toString() ?? '';
        final channelName = friend['channelName'] ?? '';
        final unreadCount = friend['unreadCount'] as int? ?? 0;
        final lastMsgTime = friend['lastMessageTime']?.toString() ?? '';
        final lastMsgText = friend['lastMessageText']?.toString() ?? '';
        final friendName = friend['friendName'] ?? friend['name'] ?? 'SikkaPlay Friend';
        
        if (friendId.isEmpty || lastMsgTime.isEmpty || unreadCount == 0) {
          continue;
        }

        final cachedTime = _lastMsgTimes[friendId];
        if (cachedTime != null && cachedTime != lastMsgTime) {
          final active = PlaygroundStudioScreen.activeChannelName;
          if (active != channelName) {
            if (lastMsgText == '__CALL_REQUEST__') {
              context.push('/playground/call', extra: {
                'isIncoming': true,
                'matchDetails': {
                  'channelName': channelName,
                  'partnerId': friendId,
                  'partnerName': friendName,
                  'agoraAppId': AppConfig.agoraAppId,
                  'agoraToken': channelName,
                }
              });
            } else {
              GameNotifications.showChatNotification(
                context, friendName, lastMsgText,
                onTap: () {
                  context.push('/playground/studio', extra: {
                    'channelName': channelName,
                    'agoraToken': channelName,
                    'partnerId': friendId,
                    'partnerName': friendName,
                    'partnerUsername': friend['username'] ?? '',
                    'partnerAvatar': friend['avatarUrl'] ?? '',
                  });
                },
              );
              _showSystemLocalNotification(friendName, lastMsgText, channelName, friendId);
            }
          }
        }
        _lastMsgTimes[friendId] = lastMsgTime;
      }
    }
  }

  void _handleIncomingMessageSocket(dynamic data) {
    try {
      final msg = data as Map<String, dynamic>;
      final senderId = msg['senderId']?.toString() ?? '';
      final channelName = msg['channelName']?.toString() ?? '';
      final text = msg['text']?.toString() ?? '';
      
      final myUserId = ref.read(userProvider).userData?['id']?.toString() ?? '';
      if (senderId == myUserId) return;

      final activeChannel = PlaygroundStudioScreen.activeChannelName ?? '';
      if (activeChannel == channelName) {
        debugPrint('[Socket] Suppressed in-app notification because user is in active chat');
        return;
      }

      final friends = ref.read(globalFriendsListProvider);
      String friendName = 'SikkaPlay Friend';
      final friend = friends.firstWhere(
        (f) => f['id']?.toString() == senderId, 
        orElse: () => null
      );
      if (friend != null) {
        friendName = friend['friendName'] ?? friend['name'] ?? 'SikkaPlay Friend';
      }

      if (mounted) {
        if (!text.startsWith('__')) {
          GameNotifications.showChatNotification(
            context,
            friendName,
            text.startsWith('[Reply to:') ? text.split('\n').sublist(1).join('\n') : text,
            onTap: () {
              context.push('/playground/studio', extra: {
                'channelName': channelName,
                'agoraToken': channelName,
                'partnerId': senderId,
                'partnerName': friendName,
              });
            },
          );
          _showSystemLocalNotification(friendName, text, channelName, senderId);
        }
      }
      
      _fetchFriendsAndCheckMessages();
    } catch (e) {
      debugPrint('Error handling incoming message socket: $e');
    }
  }

  Future<void> _showSystemLocalNotification(
      String friendName, String text, String channelName, String friendId) async {
    try {
      final payloadData = json.encode({
        'channelName': channelName,
        'partnerId': friendId,
        'partnerName': friendName,
      });

      const androidDetails = AndroidNotificationDetails(
        'sikkaplay_high_channel',
        'SikkaPlay Notifications',
        channelDescription: 'Main notification channel for SikkaPlay',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF7C3AED),
        icon: 'ic_launcher',
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);

      final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();
      await localPlugin.show(
        id: (channelName.hashCode ^ text.hashCode).abs(),
        title: friendName,
        body: text,
        notificationDetails: details,
        payload: payloadData,
      );
    } catch (e) {
      debugPrint('Error showing system notification inside poll: $e');
    }
  }

  bool _isPlaygroundMode(String location) {
    return location.startsWith('/playground');
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isPgMode = _isPlaygroundMode(location);
    
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/games')) return 1;
    
    if (isPgMode) {
      if (location.startsWith('/playground/friends')) return 3; // Chats highlighted
      return 2; // Rocket highlighted for main playground
    }
    
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, WidgetRef ref) async {
    final selectedIndex = _getSelectedIndex(context);
    
    // Asynchronously refresh corresponding tab data silently in background to keep transitions buttery smooth
    if (index == 0) {
      ref.read(homeProvider.notifier).refresh(silent: true);
      ref.read(userProvider.notifier).refresh(silent: true);
    } else if (index == 3) {
      ref.read(walletProvider.notifier).fetchWalletData();
      ref.read(userProvider.notifier).refresh(silent: true);
    } else if (index == 4) {
      ref.read(userProvider.notifier).refresh(silent: true);
    }
    
    // Close any open bottom sheet or dialog on root navigator before tab change
    final rootNav = rootNavigatorKey.currentState;
    if (rootNav != null && rootNav.canPop()) {
      rootNav.pop();
    }
    
    // Close any open bottom sheet or dialog on shell navigator before tab change
    final shellNav = shellNavigatorKey.currentState;
    if (shellNav != null && shellNav.canPop()) {
      shellNav.pop();
    }

    if (mounted) _navigateToIndex(index, ref);
  }

  void _navigateToIndex(int index, WidgetRef ref, {bool isBack = false}) {
    if (!isBack) {
      final history = ref.read(navigationHistoryProvider);
      if (history.isEmpty || history.last != index) {
        ref.read(navigationHistoryProvider.notifier).state = [...history, index];
      }
    }

    final location = GoRouterState.of(context).matchedLocation;
    final isPgMode = _isPlaygroundMode(location);

    String route = '/home';
    if (index == 0) route = '/home';
    else if (index == 1) route = '/games';
    else if (index == 2) route = '/playground';
    else if (index == 3) {
      if (isPgMode) route = '/playground/friends';
      else route = '/wallet';
    }
    else if (index == 4) {
      if (isPgMode) route = '/wallet';
      else route = '/profile';
    }

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final location = GoRouterState.of(context).matchedLocation;
    final isNavHidden = location.contains('/matchmaking') || 
                        location.contains('/playground/shop') || 
                        location.contains('/playground/studio') ||
                        location.contains('/search');
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final selectedLanguage = ref.watch(languageProvider);

    ref.listen<UserState>(userProvider, (previous, next) {
      final myUserId = next.userData?['id']?.toString() ?? '';
      if (myUserId.isNotEmpty && _globalSocket != null && _globalSocket!.connected) {
        debugPrint('[Socket] User ID loaded, joining room: friend-chat-$myUserId');
        _globalSocket!.emit('join_room', 'friend-chat-$myUserId');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final navHistory = ref.read(navigationHistoryProvider);
        if (navHistory.length > 1) {
          // Go back to previous tab
          final newHistory = List<int>.from(navHistory)..removeLast();
          ref.read(navigationHistoryProvider.notifier).state = newHistory;
          final prevIndex = newHistory.last;
          _navigateToIndex(prevIndex, ref, isBack: true);
        } else {
          // Double tap to exit
          final now = DateTime.now();
          if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('press_back_exit', selectedLanguage), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content Area
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: (isNavHidden || isKeyboardOpen) ? 0.0 : 80.0), // Room for bottom nav bar only when visible and keyboard closed
              child: widget.child,
            ),
          ),
          
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // Bottom Navigation Bar
          if (!isNavHidden && !isKeyboardOpen)
            Positioned(
              left: AppSizes.md,
              right: AppSizes.md,
              bottom: AppSizes.md,
              child: Container(
                color: Colors.transparent,
                child: SafeArea(
                  top: false,
                  bottom: true, // Always apply safe area padding at the bottom so buttons stay above the system gesture bar
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, ref, 0, Icons.home_rounded, context.tr('home', selectedLanguage), selectedIndex, false),
                        _buildNavItem(context, ref, 1, Icons.sports_esports_rounded, context.tr('play_games', selectedLanguage), selectedIndex, false),
                        _buildNavItem(context, ref, 2, Icons.rocket_launch_rounded, selectedLanguage == 'Hindi' ? 'प्लेग्राउंड' : 'Playground', selectedIndex, false),
                        
                        if (_isPlaygroundMode(location)) ...[
                          _buildNavItem(context, ref, 3, Icons.chat_bubble_rounded, selectedLanguage == 'Hindi' ? 'चैट्स' : 'Chats', selectedIndex, false),
                          _buildNavItem(context, ref, 4, Icons.account_balance_wallet_rounded, context.tr('wallet', selectedLanguage), selectedIndex, false),
                        ] else ...[
                          _buildNavItem(context, ref, 3, Icons.account_balance_wallet_rounded, context.tr('wallet', selectedLanguage), selectedIndex, false),
                          _buildNavItem(context, ref, 4, Icons.person_rounded, context.tr('profile', selectedLanguage), selectedIndex, false),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
    bool isReels,
  ) {
    if (index == 2) {
      // Big Center Rocket Button
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onItemTapped(index, ref),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2BE2), Color(0xFF6F5EFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6F5EFA).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isSelected = index == selectedIndex;
    final color = isSelected 
        ? (isReels ? AppColors.secondary : AppColors.primary)
        : (isReels ? Colors.white60 : AppColors.textSecondary);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, ref),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isReels ? Colors.white.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: AppSizes.getResponsiveFontSize(context, 10),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
