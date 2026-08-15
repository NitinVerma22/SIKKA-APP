import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/core/config/app_config.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/wallet/controllers/wallet_controller.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _selectedLanguage = 'English';
  int _currentTipIndex = 0;
  Timer? _tipTimer;
  bool _isDataPreloaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _startTipTimer();
    _navigateToOnboarding();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage = prefs.getString('app_language') ?? 'English';
      });
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  List<String> _getLocalizedTips() {
    if (_selectedLanguage == 'Hindi') {
      return [
        'डेली कोड्स रोजाना टेलीग्राम पर अपडेट किए जाते हैं! 📣',
        'अधिकतम सिक्का पाने के लिए सभी दैनिक कार्यों को पूरा करें! 🎯',
        'दोस्तों को रेफर करें और उनकी कमाई पर कमीशन पाएं! 👥',
        'अपनी गुल्लक को तुरंत भरने के लिए रील्स देखें! 📺',
        'अपनी स्पीड टेस्ट करने और कमाने के लिए इमोजी मेमोरी खेलें! 🧠',
        'अपने दिमाग को चुनौती देने के लिए मैथ रश खेलें! ⚡',
      ];
    }
    return [
      'Daily codes are updated daily on Telegram! 📣',
      'Complete all daily tasks to claim maximum Sikka! 🎯',
      'Refer friends to earn commission on their earnings! 👥',
      'Watch reels to fill up your Gullaks instantly! 📺',
      'Play Emoji Memory to test your speed & earn! 🧠',
      'Play Math Rush to challenge your brain! ⚡',
    ];
  }

  void _startTipTimer() {
    _tipTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _getLocalizedTips().length;
        });
      }
    });
  }

  bool _isVersionOlder(String current, String latest) {
    try {
      final List<int> currentParts = current.split('.').map(int.parse).toList();
      final List<int> latestParts = latest.split('.').map(int.parse).toList();
      
      for (int i = 0; i < latestParts.length; i++) {
        final currPart = i < currentParts.length ? currentParts[i] : 0;
        final latePart = latestParts[i];
        if (currPart < latePart) return true;
        if (currPart > latePart) return false;
      }
    } catch (_) {
      return current != latest;
    }
    return false;
  }

  void _navigateToOnboarding() async {
    final startTime = DateTime.now();

    // Start prefetching config
    final configService = ConfigService();
    Future<Map<String, dynamic>?> configFuture = configService.getAppConfig()
        .timeout(const Duration(milliseconds: 2000))
        .catchError((e) {
          debugPrint('Config fetch failed: $e');
          return null;
        });

    // Read token to check if we can prefetch user data in parallel
    const secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'jwt_token');

    List<Future<dynamic>> prefetchFutures = [configFuture];
    Future<void>? preloadFuture;

    if (token != null && token.isNotEmpty) {
      preloadFuture = Future.wait<void>([
        ref.read(userProvider.notifier).fetchProfile(silent: true),
        ref.read(homeProvider.notifier).refresh(silent: true),
        ref.read(walletProvider.notifier).fetchWalletData(),
        ref.read(networkProvider.notifier).fetchNetwork(),
      ]).timeout(const Duration(seconds: 30)).catchError((e) {
        debugPrint('Preloading dashboard data failed or timed out: $e');
      });
      prefetchFutures.add(preloadFuture);
    }

    // Wait for all prefetching to finish (config + user data if logged in)
    await Future.wait(prefetchFutures);
    _isDataPreloaded = true;

    final config = await configFuture;

    // Ensure exactly 1.0 second (1000ms) minimum splash time for branding visibility
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remainingDelay = 1000 - elapsed;
    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }
    
    if (mounted) {
      if (config != null) {
        // 1. Check Maintenance Mode
        final maintenanceMode = config['maintenanceMode'] as bool? ?? false;
        if (maintenanceMode) {
          context.go('/maintenance');
          return;
        }

        // 2. Check App Version Update
        final latestVersion = config['latestVersion'] as String;
        final updateUrl = config['updateUrl'] as String;
        final forceUpdate = config['forceUpdate'] as bool;
        
        if (_isVersionOlder(AppConfig.currentVersion, latestVersion)) {
          if (forceUpdate) {
            context.go('/update_app', extra: {'updateUrl': updateUrl});
            return; // Stop navigation, wait for update
          } else {
            _showUpdateDialog(updateUrl, forceUpdate);
            return; // Stop navigation, wait for dialog action
          }
        }
      }
      
      _continueNavigation();
    }
  }

  void _continueNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChosenLanguage = prefs.containsKey('app_language');
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    const secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'jwt_token');

    if (token != null && token.isNotEmpty) {
      // Preload all core providers concurrently to ensure instant load on home/wallet pages if not already preloaded
      if (!_isDataPreloaded) {
        try {
          await Future.wait<void>([
            ref.read(userProvider.notifier).fetchProfile(silent: true),
            ref.read(homeProvider.notifier).refresh(silent: true),
            ref.read(walletProvider.notifier).fetchWalletData(),
            ref.read(networkProvider.notifier).fetchNetwork(),
          ]).timeout(const Duration(seconds: 35));
          _isDataPreloaded = true;
        } catch (e) {
          debugPrint('Preloading data failed or timed out: $e');
        }
      }

      // Check if token was cleared (indicating 403 Forbidden suspension occurred during preload)
      final checkToken = await secureStorage.read(key: 'jwt_token');
      if (checkToken == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      if (mounted) {
        final pendingRouteStr = prefs.getString('pending_chat_route');
        if (pendingRouteStr != null && pendingRouteStr.isNotEmpty) {
          try {
            final Map<String, dynamic> data = json.decode(pendingRouteStr);
            final String channelName = data['channelName'] ?? '';
            final String partnerId = data['partnerId'] ?? '';
            final String partnerName = data['partnerName'] ?? 'SikkaPlay Friend';
            final String partnerAvatar = data['senderAvatar'] ?? '';
            
            if (partnerId.isNotEmpty || channelName.isNotEmpty) {
              await prefs.remove('pending_chat_route');
              final String effectiveChannel = partnerId.isNotEmpty ? 'friend-chat-$partnerId' : channelName;
              if (mounted) {
                context.go('/playground/friends');
                context.push('/playground/studio', extra: {
                  'channelName': effectiveChannel,
                  'agoraToken': effectiveChannel,
                  'partnerId': partnerId,
                  'partnerName': partnerName,
                  'partnerUsername': '',
                  'partnerAvatar': partnerAvatar,
                });
              }
              return;
            }
          } catch (e) {
            debugPrint('Error parsing pending chat route: $e');
          }
        }
        if (mounted) {
          context.go('/home'); // Session active, verified, and preloaded
        }
      }
    } else if (!hasChosenLanguage) {
      if (mounted) context.go('/language'); // Guide to language selection first
    } else if (hasSeenOnboarding) {
      if (mounted) context.go('/login'); // Seen onboarding but not logged in
    } else {
      if (mounted) context.go('/onboarding'); // Fresh install, bypassed language screen selection
    }
  }

  void _showUpdateDialog(String updateUrl, bool forceUpdate) {
    final isHindi = _selectedLanguage == 'Hindi';
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                isHindi ? 'अपडेट उपलब्ध है!' : 'Update Available!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isHindi 
                ? 'SikkaPlay का एक नया संस्करण उपलब्ध है। नवीनतम सुविधाओं और बग फिक्स प्राप्त करने के लिए कृपया अपडेट करें।'
                : 'A new version of SikkaPlay is available. Please update to get the latest features and bug fixes.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _continueNavigation();
                },
                child: Text(
                  isHindi ? 'बाद में' : 'Later',
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final url = Uri.parse(updateUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                isHindi ? 'अभी अपडेट करें' : 'Update Now',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFEBE9FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Logo & Name
          Center(
            child: FadeInSlideWidget(
              duration: const Duration(milliseconds: 1000),
              slideOffset: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PulseWidget(
                    duration: const Duration(milliseconds: 1500),
                    scaleFactor: 0.1,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    'SikkaPlay',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: AppSizes.getResponsiveFontSize(context, 38),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          foreground: Paint()
                            ..shader = AppColors.primaryGradient.createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                            ),
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _selectedLanguage == 'Hindi' ? 'खेलें • कमाएं • राज करें' : 'Play • Earn • Rule',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          fontSize: AppSizes.getResponsiveFontSize(context, 13),
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom loading tips indicator to keep users engaged (Beautiful card display above loading bar)
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: FadeInSlideWidget(
              duration: const Duration(milliseconds: 1200),
              slideOffset: 10,
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey<int>(_currentTipIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _getLocalizedTips()[_currentTipIndex],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
