import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/features/home/widgets/social_join_tasks_widget.dart';
import 'package:sikkaplay/shared/widgets/native_ad_widget.dart';
import 'package:sikkaplay/features/home/widgets/daily_streak_widget.dart';
import 'package:sikkaplay/features/home/widgets/promo_carousel.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/wallet/controllers/wallet_controller.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';

import 'dart:async';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sikkaplay/core/navigation/app_navigator.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/services/adscalex_offerwall_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _configTimer;
  bool _dialogShown = false;

  // Social Task Verification State
  SocialTask? _pendingSocialTask;
  DateTime? _socialClickTime;
  bool _isValidating = false;
  Timer? _validationTimer;
  int _validationSecondsRemaining = 0;
  
  bool _isAdScaleXOpening = false;

  Future<void> _preloadAllData() async {
    if (!mounted) return;
    try {
      await Future.wait([
        ref.read(userProvider.notifier).fetchProfile(silent: true),
        ref.read(homeProvider.notifier).refresh(silent: true),
        ref.read(walletProvider.notifier).fetchWalletData(),
        ref.read(networkProvider.notifier).fetchNetwork(),
      ]);
    } catch (e) {
      debugPrint('Background preloading failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch initial config and check updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appConfigProvider.notifier).fetchConfig();
      _preloadAllData();
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    try {
      // 1. Core notification permissions (Android 13+ / iOS)
      await Permission.notification.request();
      await FirebaseMessaging.instance.requestPermission();

      // 2. Safely prompt FCM setup permissions
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      // 3. Storage/Photos permissions as originally configured
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
      debugPrint('Error requesting permissions on home screen: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configTimer?.cancel();
    _validationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingSocialClaim();
      ref.read(appConfigProvider.notifier).fetchConfig();
    }
  }

  void _checkPendingSocialClaim() {
    if (_pendingSocialTask == null || _socialClickTime == null) return;

    final clickTime = _socialClickTime!;
    final task = _pendingSocialTask!;

    _pendingSocialTask = null;
    _socialClickTime = null;

    final elapsed = DateTime.now().difference(clickTime).inSeconds;
    debugPrint('Social join task validation: elapsed time = $elapsed seconds');

    if (elapsed < 10) {
      _showFollowWarningDialog();
    } else if (elapsed < 20) {
      final remaining = 20 - elapsed;
      _showValidationLoader(remaining, task);
    } else {
      _triggerInterstitialAdAndClaim(task);
    }
  }

  void _showConfigChangedDialog() {
    if (_dialogShown) return;
    _dialogShown = true;
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(context.tr('alert_title', selectedLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            context.tr('config_change_alert', selectedLanguage),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ),
    );
  }

  void _handleSocialJoin(BuildContext context, WidgetRef ref, SocialTask task) {
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SocialBenefitsDialog(
        task: task,
        selectedLanguage: selectedLanguage,
        onJoinPressed: (url) async {
          setState(() {
            _pendingSocialTask = task;
            _socialClickTime = DateTime.now();
          });

          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            debugPrint('Could not launch social link: $e');
          }
        },
      ),
    );
  }

  void _showFollowWarningDialog() {
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              selectedLanguage == 'Hindi' ? 'कृपया फॉलो करें' : 'Please Follow',
              style:
                  GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          selectedLanguage == 'Hindi'
              ? 'कृपया पहले सोशल मीडिया पेज पर जाएं और हमें फॉलो करें/ज्वाइन करें!'
              : 'Please follow or join our official channel to claim your reward coins.',
          style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              selectedLanguage == 'Hindi' ? 'ठीक है' : 'OK',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationLoader(int seconds, SocialTask task) {
    setState(() {
      _isValidating = true;
      _validationSecondsRemaining = seconds;
    });

    final selectedLanguage = ref.read(languageProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              _validationTimer?.cancel();
              _validationTimer =
                  Timer.periodic(const Duration(seconds: 1), (timer) {
                if (_validationSecondsRemaining <= 1) {
                  timer.cancel();
                  Navigator.of(context).pop(); // Close validation dialog
                  setState(() {
                    _isValidating = false;
                  });
                  _triggerInterstitialAdAndClaim(task);
                } else {
                  if (context.mounted) {
                    setDialogState(() {
                      _validationSecondsRemaining--;
                    });
                  }
                }
              });

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        selectedLanguage == 'Hindi'
                            ? 'ज्वाइन स्थिति सत्यापित की जा रही है... 🔍'
                            : 'Validating join status... 🔍',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedLanguage == 'Hindi'
                            ? 'सत्यापन हो रहा है, कृपया $_validationSecondsRemaining सेकंड प्रतीक्षा करें'
                            : 'Verifying, please wait $_validationSecondsRemaining seconds',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      _validationTimer?.cancel();
    });
  }

  void _triggerInterstitialAdAndClaim(SocialTask task) {
    final selectedLanguage = ref.read(languageProvider);
    final userState = ref.read(userProvider);
    final userId = userState.userData?['id'] ?? '';
    final coinsEarned = task.rewardAmount;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(context.tr('user_session_expired', selectedLanguage))),
      );
      return;
    }

    final onCompleteClaim = () async {
      final success = await ref
          .read(userProvider.notifier)
          .claimDynamicSocialTask(task.id, coinsEarned);
      if (mounted) {
        if (success) {
          ref
              .read(homeProvider.notifier)
              .completeSocialTask(task.id, coinsEarned);
          _showRewardCreditedDialog(coinsEarned);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(context.tr('coins_claimed_failed', selectedLanguage)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    };

    if (!AdService.instance.isInterstitialAdLoaded()) {
      AdService.instance.loadInterstitialAd();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FakeAdDialog(
          title: selectedLanguage == 'Hindi'
              ? 'मनोरंजन पुरस्कार'
              : 'Social Reward Ad',
          message: selectedLanguage == 'Hindi'
              ? 'रिवॉर्ड क्लेम करने के लिए विज्ञापन देखें'
              : 'Watch short ad to claim your reward',
          onComplete: onCompleteClaim,
        ),
      );
    } else {
      AdService.instance.showInterstitialAd(
        onAdDismissed: () {
          // Wait 5 seconds after ad starts/dismisses and claim coins
          Future.delayed(const Duration(seconds: 5), () {
            onCompleteClaim();
          });
        },
      );
    }
  }

  void _showRewardCreditedDialog(int coinsEarned) {
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFD600),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('coins_credited_title', selectedLanguage),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context
                  .tr('coins_credited_desc', selectedLanguage)
                  .replaceAll('{coins}', '$coinsEarned'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                text: context.tr('awesome_btn', selectedLanguage),
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final userState = ref.watch(userProvider);
    final selectedLanguage = ref.watch(languageProvider);
    final userData = userState.userData ?? {};
    final balance = userData['balance'] ?? homeState.balance;
    final referralEarning =
        userData['referralBalance'] ?? homeState.referralEarning;
    final userName = userData['name'] ?? 'SikkaPlay User';

    // Calculate level based on total earned (e.g. 1000 coins = 1 level)
    final totalEarned = userData['totalEarned'] ?? 0;
    final userLevel = (totalEarned / 1000).floor() + 1;

    // Listen to config changes
    final configState = ref.watch(appConfigProvider);
    if (configState.hasChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfigChangedDialog();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAEAFB), // Soft lavender top
              Color(0xFFF7F8FC), // Muted white/grey bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(appConfigProvider.notifier).fetchConfig();
              await _preloadAllData();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Compact Wallet
                  _buildHeader(context, ref, balance + referralEarning,
                      userName, userLevel),
                  const SizedBox(height: AppSizes.lg),

                  // Daily Code Banner
                  const PromoCarousel(),
                  const SizedBox(height: AppSizes.lg),

                  _buildAnnouncementBar(context, selectedLanguage),
                  const SizedBox(height: AppSizes.lg),

                  if (configState.config?['showVideoTutorialBar'] ?? true)
                    _buildVideoTutorialBar(context, selectedLanguage),
                  if (configState.config?['showVideoTutorialBar'] ?? true)
                    const SizedBox(height: AppSizes.lg),

                  // 2. Daily Streak Widget (Restored at the top)
                  const DailyStreakWidget(),
                  const SizedBox(height: AppSizes.lg),

                  // 4. Earning Tasks Grid
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                    child: Text(
                      context.tr('ways_to_earn', selectedLanguage),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Grid items (2-column, 3 rows)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85, 
                    children: [
                      _buildNewGridCard(
                        title: 'Spin Wheel',
                        subtitleWidget: RichText(
                          maxLines: 4,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: 'Win upto\n'),
                              TextSpan(text: '90\nCoins', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w900, fontSize: 22)),
                            ],
                          ),
                        ),
                        badgeText: 'EASY & FUN',
                        badgeColor: const Color(0xFFFFCDD2).withOpacity(0.6),
                        badgeTextColor: const Color(0xFFC62828),
                        bgColor: const Color(0xFFFFF0F5),
                        buttonGradient: const [Color(0xFFFF4081), Color(0xFFE91E63)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/spin_wheel.png'),
                          onTap: () => AppNavigator.push(context, ref, '/games/spin_earn'),
                      ),
                      _buildNewGridCard(
                        title: 'Daily Code',
                        subtitleWidget: RichText(
                          maxLines: 4,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: 'Win upto\n'),
                              TextSpan(text: '2000\nCoins', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 22)),
                            ],
                          ),
                        ),
                        badgeText: 'DAILY',
                        badgeColor: const Color(0xFFBBDEFB).withOpacity(0.6),
                        badgeTextColor: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFF0F8FF),
                        buttonGradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/daily_code.png'),
                          onTap: () => AppNavigator.push(context, ref, '/home/daily_code'),
                      ),
                      _buildNewGridCard(
                        title: 'Complete Offers',
                        subtitleWidget: RichText(
                          maxLines: 4,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500, height: 1.1),
                            children: [
                              TextSpan(text: 'Win upto\n'),
                              TextSpan(text: '50000\nCoins\n', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w900, fontSize: 22)),
                              TextSpan(text: 'per day', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        badgeText: 'HIGH REWARDS',
                        badgeColor: const Color(0xFFFFE0B2).withOpacity(0.6),
                        badgeTextColor: const Color(0xFFE65100),
                        bgColor: const Color(0xFFFFF8E1),
                        buttonGradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/offers.png'),
                          onTap: () {
                          if (_isAdScaleXOpening) return;
                          setState(() {
                            _isAdScaleXOpening = true;
                          });
                          final userState = ref.read(userProvider);
                          final configState = ref.read(appConfigProvider);
                          final userId = userState.userData?['id']?.toString() ?? userState.userData?['_id']?.toString() ?? '';
                          final remoteAppKey = configState.config?['adScaleXAppKey'] ?? configState.config?['adscalexAppKey'];
                          final appKey = remoteAppKey?.toString() ?? 'psk_NfPTjRGS0a5f6vcljv0ScBZohLYIxOFsdfCRE9kfrtQ';
                          
                          AdScaleXOfferwallService.openOfferwall(context, userId, appKey)
                              .whenComplete(() {
                            if (mounted) {
                              setState(() {
                                _isAdScaleXOpening = false;
                              });
                            }
                          });
                        },
                      ),
                      _buildNewGridCard(
                        title: 'Complete Surveys',
                        subtitleWidget: RichText(
                          maxLines: 4,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: 'Earn upto\n'),
                              TextSpan(text: '5000\nCoins', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.w900, fontSize: 22)),
                            ],
                          ),
                        ),
                        badgeText: 'POPULAR',
                        badgeColor: const Color(0xFFE1BEE7).withOpacity(0.6),
                        badgeTextColor: const Color(0xFF6A1B9A),
                        bgColor: const Color(0xFFF3E5F5),
                        buttonGradient: const [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/surveys.png'),
                          onTap: () => AppNavigator.push(context, ref, '/home/surveys'),
                      ),
                      _buildNewGridCard(
                        title: 'Make Team',
                        subtitleWidget: RichText(
                          maxLines: 4,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500, height: 1.1),
                            children: [
                              TextSpan(text: 'Earn upto\n'),
                                TextSpan(text: '10000\nCoins\n', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w900, fontSize: 22)),
                                TextSpan(text: 'per person'),
                            ],
                          ),
                        ),
                        badgeText: 'QUICK EARN',
                        badgeColor: const Color(0xFFC8E6C9).withOpacity(0.6),
                        badgeTextColor: const Color(0xFF2E7D32),
                        bgColor: const Color(0xFFE8F5E9),
                        buttonGradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/networks.png'),
                          onTap: () => AppNavigator.push(context, ref, '/my_network'),
                      ),
                      _buildNewGridCard(
                        title: 'Make Friends\nTake Gifts',
                        subtitleWidget: const Text(
                            'Connect,\nchat and\nget gifts!',
                            maxLines: 3,
                            style: TextStyle(fontSize: 14, color: Color(0xFFC2185B), fontWeight: FontWeight.w800, height: 1.1),
                          ),
                        badgeText: 'SOCIAL',
                        badgeColor: const Color(0xFFF8BBD0).withOpacity(0.6),
                        badgeTextColor: const Color(0xFFC2185B),
                        bgColor: const Color(0xFFFCE4EC),
                        buttonGradient: const [Color(0xFFEC407A), Color(0xFFD81B60)],
                        buttonText: 'Lets Go',
                        imageWidget: Image.asset('assets/images/home_cards/friends.png'),
                          onTap: () => AppNavigator.push(context, ref, '/playground/friends'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Native Ad below Ways to Earn
                  const NativeAdWidget(),
                  const SizedBox(height: AppSizes.xl),

                  // 5. Refer & Earn Banner
                  FadeInSlideWidget(
                    slideOffset: 28,
                    duration: const Duration(milliseconds: 750),
                    child: _buildReferralBanner(context),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // 6. Social Join Tasks
                  FadeInSlideWidget(
                    slideOffset: 30,
                    duration: const Duration(milliseconds: 800),
                    child: SocialJoinTasksWidget(
                      tasks: homeState.socialTasks,
                      onJoin: (task) {
                        _handleSocialJoin(context, ref, task);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Native Ad below Join and Earn (Taller for Video)
                  const NativeAdWidget(isSmallCard: false),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewGridCard({
    required String title,
    required Widget subtitleWidget,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required Color bgColor,
    required List<Color> buttonGradient,
    required String buttonText,
    required Widget imageWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.only(left: 10, top: 12, bottom: 12, right: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Right side image
            Positioned(
                right: -15,
                bottom: 15,
                child: SizedBox(
                  width: 95,
                  height: 95,
                child: imageWidget,
              ),
            ),
            
            // Left side content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                
                // Title
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                
                // Subtitle
                subtitleWidget,
                
                const Spacer(),
                
                // Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: buttonGradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCodeBanner(BuildContext context, String selectedLanguage) {
    return GestureDetector(
      onTap: () => context.push('/home/daily_code'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF863BFF),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF863BFF).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21.5),
          child: Image.asset(
            'assets/images/daily_code.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 100,
              color: const Color(0xFF863BFF).withValues(alpha: 0.1),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_rounded,
                      color: Color(0xFF863BFF), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('daily_code_banner', selectedLanguage),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF863BFF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTutorialBar(BuildContext context, String selectedLanguage) {
    return GestureDetector(
      onTap: () => context.push('/home/video_tutorials'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE52D27), Color(0xFFB31217)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE52D27).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use Sikka Play',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Watch video to learn',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBar(BuildContext context, String selectedLanguage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9E00), Color(0xFFFF6B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9E00).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: MarqueeWidget(
              child: Text(
                context.tr('announcement_marquee', selectedLanguage),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanners(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '/games/spin_earn'), // Clicking the banner opens the spin wheel game
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/promo_banner.webp'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigator.pushWithContainer(
          context, '/my_network'), // Clicking the banner opens the network page
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/referral_banner.webp'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, int balance,
      String userName, int level) {
    // Split userName into first character and rest of name to place a tiny tilted crown on first letter
    final String firstLetter = userName.isNotEmpty ? userName.trim()[0] : '';
    final String restOfName =
        userName.trim().length > 1 ? userName.trim().substring(1) : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main avatar containing app logo (fallback to esports/gaming logo icon)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6E5DE7), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6E5DE7).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.sports_esports_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online indicator on bottom-right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), // Green dot
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SikkaPlay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontSize:
                                AppSizes.getResponsiveFontSize(context, 18),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (firstLetter.isNotEmpty)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Text(
                                firstLetter,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.getResponsiveFontSize(
                                      context, 13),
                                ),
                              ),
                              const Positioned(
                                top: -9,
                                left: -4,
                                child: RotationTransition(
                                  turns: AlwaysStoppedAnimation(-15 / 360),
                                  child: Text(
                                    '👑',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (restOfName.isNotEmpty)
                          Flexible(
                            child: Text(
                              restOfName,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    AppSizes.getResponsiveFontSize(context, 13),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Compact Wallet matching the image design exactly
        GestureDetector(
          onTap: () => AppNavigator.push(context, ref, '/wallet'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sikka Coin
                const Icon(
                  Icons.monetization_on,
                  color: AppColors.yellowGlow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GlowingBorderCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;

  const GlowingBorderCard({
    super.key,
    required this.child,
    required this.gradientColors,
  });

  @override
  State<GlowingBorderCard> createState() => _GlowingBorderCardState();
}

class _GlowingBorderCardState extends State<GlowingBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(2.5), // border width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1.5,
              ),
            ],
            gradient: SweepGradient(
              colors: [
                Colors.transparent,
                widget.gradientColors[0],
                widget.gradientColors[1],
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;

  const MarqueeWidget({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(seconds: 8),
    this.backDuration = const Duration(milliseconds: 1000),
    this.pauseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll() async {
    while (_scrollController.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent > 0) {
          await _scrollController.animateTo(
            maxExtent,
            duration: widget.animationDuration,
            curve: Curves.linear,
          );
          await Future.delayed(widget.pauseDuration);
        }
      }
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: widget.direction,
      physics: const NeverScrollableScrollPhysics(),
      child: widget.child,
    );
  }
}

class _SocialBenefitsDialog extends StatefulWidget {
  final SocialTask task;
  final String selectedLanguage;
  final Function(String url) onJoinPressed;

  const _SocialBenefitsDialog({
    required this.task,
    required this.selectedLanguage,
    required this.onJoinPressed,
  });

  @override
  State<_SocialBenefitsDialog> createState() => _SocialBenefitsDialogState();
}

class _SocialBenefitsDialogState extends State<_SocialBenefitsDialog> {
  int _secondsLeft = 2;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.selectedLanguage == 'Hindi';
    final task = widget.task;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: task.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(task.icon, color: task.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isHindi ? 'जुड़ें और कमाएं 🚀' : 'Join & Earn 🚀',
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi
                ? 'हमारे आधिकारिक ${task.platform} से जुड़ने के लाभ:'
                : 'Benefits of joining our official ${task.platform}:',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            isHindi
                ? 'वास्तविक समय की घोषणाएं और अपडेट प्राप्त करें'
                : 'Receive real-time announcements & updates',
          ),
          _buildBenefitItem(
            isHindi
                ? 'विशेष इनाम कोड और भविष्य की योजनाएं'
                : 'Get exclusive reward codes & future plans',
          ),
          _buildBenefitItem(
            isHindi
                ? 'SikkaPlay समुदाय का हिस्सा बनें'
                : 'Become part of the SikkaPlay community',
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            text: _secondsLeft > 0
                ? (isHindi
                    ? 'ज्वाइन करें (${_secondsLeft}s)'
                    : 'Join Now (${_secondsLeft}s)')
                : (isHindi ? 'ज्वाइन करें' : 'Join Now'),
            onTap: _secondsLeft > 0
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onJoinPressed(task.link);
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}



