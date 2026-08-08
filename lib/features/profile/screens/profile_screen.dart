import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/features/notifications/providers/notification_provider.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';

import 'package:sikkaplay/shared/models/badge_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _upiController = TextEditingController();
  
  // Wallet Stats State for Earnings Summary and Today's Earning
  Map<String, dynamic>? _walletStats;
  
  final ScrollController _scrollController = ScrollController();
  final ScrollController _badgesScrollController = ScrollController();

  int _selectedAvatarIndex = 0;

  final PlaygroundService _playgroundService = PlaygroundService();
  List<dynamic> _giftInventory = [];
  bool _showAllGifts = false;
  bool _loadingGifts = false;
  bool _isUploadingAvatar = false;

  final List<Map<String, dynamic>> avatarOptions = [
    // Male Avatars (1 to 6)
    {'image': 'assets/images/profile/avatar_1.webp', 'fallbackIcon': Icons.sports_esports_rounded, 'gradient': [const Color(0xFF6F5EFA), const Color(0xFF9B82FF)]},
    {'image': 'assets/images/profile/avatar_2.webp', 'fallbackIcon': Icons.emoji_events_rounded, 'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)]},
    {'image': 'assets/images/profile/avatar_3.webp', 'fallbackIcon': Icons.local_fire_department_rounded, 'gradient': [const Color(0xFFEF4444), const Color(0xFFFF7E40)]},
    {'image': 'assets/images/profile/avatar_4.webp', 'fallbackIcon': Icons.star_rounded, 'gradient': [const Color(0xFF06D6A0), const Color(0xFF00B4D8)]},
    {'image': 'assets/images/profile/avatar_5.webp', 'fallbackIcon': Icons.auto_awesome_rounded, 'gradient': [const Color(0xFF7209B7), const Color(0xFFB5179E)]},
    {'image': 'assets/images/profile/avatar_6.webp', 'fallbackIcon': Icons.favorite_rounded, 'gradient': [const Color(0xFFEC4899), const Color(0xFFFF758C)]},
    // Female Avatars (7 to 12)
    {'image': 'assets/images/profile/avatar_7.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFFFF758C), const Color(0xFFFF7E40)]},
    {'image': 'assets/images/profile/avatar_8.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]},
    {'image': 'assets/images/profile/avatar_9.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF00B4D8), const Color(0xFF6E5DE7)]},
    {'image': 'assets/images/profile/avatar_10.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF06D6A0), const Color(0xFF10B981)]},
    {'image': 'assets/images/profile/avatar_11.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFFFB8500), const Color(0xFFFFB703)]},
    {'image': 'assets/images/profile/avatar_12.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF7209B7), const Color(0xFF3F51B5)]},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadSelectedAvatar();
    _loadPlaygroundGifts();
    
    // Refresh user profile and network silently on entering the profile screen to fetch latest referral count & balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userProvider.notifier).refresh(silent: true);
        ref.read(networkProvider.notifier).fetchNetwork();
      }
    });
  }

  Future<void> _loadPlaygroundGifts() async {
    if (!mounted) return;
    setState(() {
      _loadingGifts = true;
    });
    try {
      final res = await _playgroundService.getLobbyData();
      if (mounted && res['success'] == true) {
        setState(() {
          _giftInventory = res['giftInventory'] ?? [];
          _loadingGifts = false;
        });
      } else {
        if (mounted) setState(() => _loadingGifts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGifts = false);
    }
  }

  String _getGiftEmoji(String giftName) {
    switch (giftName.trim().toLowerCase()) {
      case 'coffee': return '☕';
      case 'heart': return '💖';
      case 'ice cream': return '🍦';
      case 'bouquet': return '💐';
      case 'rose': return '🌹';
      case 'watch': return '⌚';
      case 'chocolate': return '🍫';
      case 'female shoes': return '👠';
      case 'boys shoes': return '👞';
      case 'crown': return '👑';
      case 'female bag': return '👜';
      case 'ring': return '💍';
      case 'dress': return '👗';
      case 'coat pant': return '👔';
      case 'jewelry': return '💎';
      case 'female jackpot': return '🛍️';
      case 'boys kit': return '💼';
      default: return '🎁';
    }
  }

  void _showSellGiftDialog(dynamic item) {
    final gift = item['gift'];
    final giftId = gift['id'];
    final giftName = gift['name'];
    final coinsPrice = gift['coinsPrice'] ?? 200;
    // Payout is coinsPrice * (1 - 0.20 commission) = 80% of price
    final payoutPerItem = (coinsPrice * 0.8).round();
    final int maxCount = item['count'] ?? 1;
    int selectedQuantity = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalPayout = payoutPerItem * selectedQuantity;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'SELL VIRTUAL GIFT',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sell $selectedQuantity x $giftName for $totalPayout Sikka Coins? (20% platform commission applies)',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                ),
                if (maxCount > 1) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Select Quantity',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF863BFF)),
                        onPressed: selectedQuantity > 1
                            ? () => setDialogState(() => selectedQuantity--)
                            : null,
                      ),
                      Text(
                        '$selectedQuantity',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF863BFF)),
                        onPressed: selectedQuantity < maxCount
                            ? () => setDialogState(() => selectedQuantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF863BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _loadingGifts = true);
                  
                  int successfulSells = 0;
                  String? lastError;
                  
                  for (int i = 0; i < selectedQuantity; i++) {
                    final res = await _playgroundService.sellVirtualGift(giftId);
                    if (res['success'] == true) {
                      successfulSells++;
                    } else {
                      lastError = res['error'];
                      break;
                    }
                  }

                  if (successfulSells > 0) {
                    if (mounted) {
                      setState(() {
                        final index = _giftInventory.indexWhere((item) => item['gift']['id'] == giftId);
                        if (index != -1) {
                          final currentCount = _giftInventory[index]['count'] ?? 1;
                          if (currentCount <= successfulSells) {
                            _giftInventory.removeAt(index);
                          } else {
                            _giftInventory[index]['count'] = currentCount - successfulSells;
                          }
                        }
                      });
                      GameNotifications.showCoinUpdate(context, 'Sold $successfulSells successfully!');
                      ref.read(homeProvider.notifier).refresh(silent: true);
                      ref.read(userProvider.notifier).refresh(silent: true);
                      // Trigger background refresh to sync with server
                      _loadPlaygroundGifts();
                    }
                  } else if (lastError != null) {
                    if (mounted) {
                      GameNotifications.showCoinUpdate(context, lastError);
                    }
                  }
                  
                  if (mounted) setState(() => _loadingGifts = false);
                },
                child: Text('SELL FOR $totalPayout COINS', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedAvatarIndex = prefs.getInt('selected_avatar_index') ?? 0;
      });
    }
  }

  Future<void> _saveSelectedAvatar(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_avatar_index', index);
    if (mounted) {
      setState(() {
        _selectedAvatarIndex = index;
      });
    }

    // Sync to backend for live avatars
    if (index > 0 && index <= avatarOptions.length) {
      final imagePath = avatarOptions[index - 1]['image'] as String;
      // We pass the asset path to the backend, which will save it as avatarUrl
      await ref.read(userServiceProvider).updateProfilePicture(imagePath);
      if (mounted) {
        await ref.read(userProvider.notifier).fetchProfile();
      }
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _scrollController.dispose();
    _badgesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ref.read(userServiceProvider).getWalletStats();
      if (mounted) {
        setState(() {
          _walletStats = stats;
        });
      }
    } catch (e) {
      // stats loading failed, defaults will be used
    }
  }

  String _formatNumber(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Image Asset with fallback Widget so compilation and UI never breaks
  Widget _buildImageWithFallback(String imagePath, double width, double height, Widget fallbackWidget) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return fallbackWidget;
      },
    );
  }

  Widget _buildBadgeImage(String imagePath, IconData fallbackIcon, Color badgeColor, {double size = 60}) {
    return _buildImageWithFallback(
      imagePath,
      size,
      size,
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [badgeColor.withValues(alpha: 0.15), badgeColor.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(fallbackIcon, color: Colors.white, size: size * 0.45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final userState = ref.watch(userProvider);
    final selectedLanguage = ref.watch(languageProvider);
    final networkState = ref.watch(networkProvider);
    final userData = userState.userData ?? {};

    final userName = userData['name'] ?? 'SikkaPlay User';
    final userPhone = userData['phoneNumber'] ?? '+91 -';
    final userCity = userData['city'] ?? 'Unknown City';
    final referralCode = userData['referralCode'] ?? 'SIKKA2026';
    final referralCount = userData['referralCount'] ?? networkState.level1.length;
    
    // Fallback logic to get the latest lifetime earnings
    final int totalEarned = homeState.totalEarning > 0 
        ? homeState.totalEarning 
        : (userData['totalEarned'] ?? 0);
    
    // Calculate level based on earnings
    final userLevel = (totalEarned / 1000).floor() + 1;

    // Calculate dynamic badge rank
    BadgeInfo? activeBadge;
    BadgeInfo? nextBadge;

    for (var badge in appBadges) {
      if (totalEarned >= badge.targetCoins) {
        activeBadge = badge;
      } else {
        nextBadge ??= badge;
      }
    }

    // Current Highest Rank Name and Next Target calculations
    final String activeRankName = activeBadge != null ? '${activeBadge.name} Rank' : 'Starter Rank';
    final int nextBadgeTarget = nextBadge?.targetCoins ?? 2000;
    final String nextRankName = nextBadge != null ? '${nextBadge.name} Rank' : 'Max Rank';
    
    // Coin progress percentage for the next badge
    final double badgeProgressValue = (totalEarned / nextBadgeTarget).clamp(0.0, 1.0);

    // Calculate games played count based on minutes
    final int gamesPlayed = homeState.gamesMinutesPlayed > 0 ? (homeState.gamesMinutesPlayed / 2).ceil() : 0;

    // Generate initials for avatar
    String initials = 'SP';
    if (userName.isNotEmpty && userName != 'SikkaPlay User') {
      final parts = userName.trim().split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = userName.substring(0, userName.length > 1 ? 2 : 1).toUpperCase();
      }
    }

    // Dynamic referral milestones progression (e.g. 5, 8, 12, 20)
    int nextReferralMilestone = 5;
    if (referralCount >= 5 && referralCount < 8) {
      nextReferralMilestone = 8;
    } else if (referralCount >= 8 && referralCount < 12) {
      nextReferralMilestone = 12;
    } else if (referralCount >= 12 && referralCount < 20) {
      nextReferralMilestone = 20;
    } else if (referralCount >= 20) {
      nextReferralMilestone = referralCount; 
    }
    final double referralProgress = (referralCount / nextReferralMilestone).clamp(0.0, 1.0);
    final int todayCoinsEarned = _walletStats != null
        ? ((_walletStats!['self']?['today'] ?? 0) + (_walletStats!['referral']?['today'] ?? 0))
        : 125; // fallback baseline

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FC), Color(0xFFECEBFC)], // Soft premium violet gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Area (No Streak Pill)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('profile', selectedLanguage),
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('profile_subtitle', selectedLanguage),
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNotificationBell(context, ref),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Premium User Details Card (Lighter vibrant purple/indigo gradient to resolve overflow)
                FadeInSlideWidget(
                  slideOffset: 15,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6F5EFA), // Slightly darker soft Indigo-purple
                          Color(0xFF9B82FF), // Slightly darker soft purple
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6F5EFA).withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Initials Avatar: sized properly to prevent layout overflow
                            GestureDetector(
                              onTap: _showAvatarSelectionSheet,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: userData['avatarUrl'] != null || _selectedAvatarIndex == 0
                                          ? null
                                          : LinearGradient(
                                              colors: avatarOptions[_selectedAvatarIndex - 1]['gradient'] as List<Color>,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      color: userData['avatarUrl'] != null || _selectedAvatarIndex == 0 ? Colors.white.withValues(alpha: 0.18) : null,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                    ),
                                    child: Center(
                                      child: userData['avatarUrl'] != null
                                          ? ClipOval(
                                              child: userData['avatarUrl'].toString().startsWith('data:image')
                                                  ? Image.memory(
                                                      base64Decode(userData['avatarUrl'].toString().split(',').last),
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Text(
                                                        initials,
                                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                                      ),
                                                    )
                                                  : userData['avatarUrl'].toString().startsWith('http')
                                                      ? CachedNetworkImage(
                                                          imageUrl: userData['avatarUrl'],
                                                          width: 60,
                                                          height: 60,
                                                          fit: BoxFit.cover,
                                                          errorWidget: (context, url, error) => Text(
                                                            initials,
                                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                                          ),
                                                        )
                                                      : Image.asset(
                                                          userData['avatarUrl'],
                                                          width: 60,
                                                          height: 60,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Text(
                                                            initials,
                                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                                          ),
                                                        ),
                                            )
                                          : _selectedAvatarIndex == 0
                                              ? Text(
                                                  initials,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                  ),
                                                )
                                              : ClipOval(
                                                  child: Image.asset(
                                                    avatarOptions[_selectedAvatarIndex - 1]['image'] as String,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Icon(
                                                      avatarOptions[_selectedAvatarIndex - 1]['fallbackIcon'] as IconData,
                                                      color: Colors.white,
                                                      size: 26,
                                                    ),
                                                  ),
                                                ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF6F5EFA),
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // User Info (White Text on Light Purple Card)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          userName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _showProfileDetailsUpdateDialog(context, userData),
                                        child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userPhone,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Level Chip (Flexible row protects long city names from overflowing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.stars_rounded, color: Colors.white, size: 11),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Level $userLevel • $userCity',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _showBioUpdateDialog(context, userData['bio']),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_note_rounded, color: Colors.white70, size: 13),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            userData['bio'] ?? (selectedLanguage == 'Hindi' ? 'बायो जोड़ें...' : 'Add playground bio...'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Dynamic Rank Badge (SizedBox limits width to prevent horizontal layouts overflow)
                            SizedBox(
                              width: 72,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildBadgeImage(
                                    activeBadge?.imagePath ?? 'assets/images/profile/badge_starter.webp',
                                    activeBadge?.fallbackIcon ?? Icons.emoji_events_rounded,
                                    activeBadge?.color ?? Colors.orangeAccent,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeRankName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                        const SizedBox(height: 12),
                        // Coins Progress Track towards NEXT badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next: $nextRankName',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_formatNumber(totalEarned)} / ${_formatNumber(nextBadgeTarget)} Sikka',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: badgeProgressValue,
                                minHeight: 10,
                                backgroundColor: Colors.black.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(badgeProgressValue * 100).toInt()}% Unlocked',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Achievements Badges (Directly under Purple Card - Replaces Stats Row)
                FadeInSlideWidget(
                  slideOffset: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('achievements', selectedLanguage),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_badgesScrollController.hasClients) {
                                _badgesScrollController.animateTo(
                                  _badgesScrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.arrow_outward,
                                size: 20,
                                color: Color(0xFF4A3AFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Height increased to 145 to comfortably fit larger badge layouts without clipping
                      SizedBox(
                        height: 145,
                        child: ListView.builder(
                          controller: _badgesScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: appBadges.length,
                          itemBuilder: (context, index) {
                            final badge = appBadges[index];
                            final isUnlocked = totalEarned >= badge.targetCoins;
                            
                            // Check if this badge is the CURRENT next in-progress milestone
                            final isNextActive = !isUnlocked && (index == 0 || totalEarned >= appBadges[index - 1].targetCoins);
                            
                            return _buildAchievementBadgeCard(
                              context: context,
                              badge: badge,
                              isUnlocked: isUnlocked,
                              isActive: isNextActive,
                              totalEarned: totalEarned,
                              prevTarget: index > 0 ? appBadges[index - 1].targetCoins : 0,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Gifts Showcase section (displays collected gifts)
                if (_giftInventory.isNotEmpty) ...[
                  FadeInSlideWidget(
                    slideOffset: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLanguage == 'Hindi' ? 'मेरे प्राप्त उपहार' : 'My Received Gifts',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5A3E9C).withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: _showAllGifts ? _giftInventory.length : (_giftInventory.length > 3 ? 3 : _giftInventory.length),
                            itemBuilder: (context, index) {
                              final item = _giftInventory[index];
                              final gift = item['gift'];
                              final count = item['count'] ?? 1;

                              return GestureDetector(
                                onTap: () => _showSellGiftDialog(item),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F8FC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFEFF0F6)),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          gift['imageUrl'] != null && gift['imageUrl'].toString().startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: gift['imageUrl'],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.contain,
                                                  errorWidget: (context, url, error) => Text(
                                                    _getGiftEmoji(gift['name'] ?? ''),
                                                    style: const TextStyle(fontSize: 32),
                                                  ),
                                                )
                                              : Text(
                                                  _getGiftEmoji(gift['name'] ?? gift['imageUrl'] ?? ''),
                                                  style: const TextStyle(fontSize: 32),
                                                ),
                                          const SizedBox(height: 6),
                                          Text(
                                            gift['name'],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF863BFF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'x$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!_showAllGifts && _giftInventory.length > 3)
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showAllGifts = true;
                                });
                              },
                              icon: const Icon(Icons.expand_more, size: 18),
                              label: const Text('View All'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF863BFF),
                              ),
                            ),
                          ),
                        if (_showAllGifts && _giftInventory.length > 3)
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showAllGifts = false;
                                });
                              },
                              icon: const Icon(Icons.expand_less, size: 18),
                              label: const Text('Show Less'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF863BFF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],




                // 5. Referral Progress Card (Full Width - Dynamic Height Layout - Referral button wont collapse)
                FadeInSlideWidget(
                  slideOffset: 22,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A3E9C).withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Sized dynamically
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline_rounded, color: Color(0xFF863BFF), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr('referral_progress', selectedLanguage),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF863BFF).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${selectedLanguage == 'Hindi' ? 'कोड' : 'Code'}: $referralCode',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF863BFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: referralCode));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(context.tr('code_copied', selectedLanguage)),
                                              backgroundColor: AppColors.primary,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F8FC),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFEFF0F6)),
                                          ),
                                          child: const Icon(Icons.copy_rounded, color: Colors.grey, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$referralCount / $nextReferralMilestone Referrals',
                                        style: const TextStyle(
                                          color: Color(0xFF863BFF),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${(referralProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: referralProgress,
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFEFEFFE),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF863BFF)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildImageWithFallback(
                                    'assets/images/profile/referral_gift.webp',
                                    115, // Made the image larger (was 96)
                                    115, // Made the image larger (was 96)
                                    const Icon(
                                      Icons.card_giftcard_rounded,
                                      color: Colors.purpleAccent,
                                      size: 72, // Made fallback icon larger (was 64)
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedLanguage == 'Hindi' ? 'कोड साझा करें और कमाएं!' : 'Share code & earn!',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF863BFF), width: 1.5),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/my_network'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.people_outline_rounded, color: Color(0xFF863BFF), size: 15),
                                          const SizedBox(width: 6),
                                          Text(
                                            context.tr('view_network', selectedLanguage),
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF863BFF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF863BFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final appConfig = ref.read(appConfigProvider).config;
                                      final appLink = appConfig?['apkDownloadUrl'] ?? 'https://sikkaplay.com';
                                      _shareReferral(referralCode, appLink);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.share_outlined, color: Colors.white, size: 15),
                                          const SizedBox(width: 6),
                                          Text(
                                            context.tr('invite_friends', selectedLanguage),
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Network Banner Image (3:1 Ratio)
                FadeInSlideWidget(
                  slideOffset: 24,
                  child: GestureDetector(
                    onTap: () => context.push('/my_network'),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AspectRatio(
                          aspectRatio: 3 / 1,
                          child: Image.asset(
                            'assets/images/profile/network.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF3F37C9),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_alt_rounded, color: Colors.white, size: 32),
                                    SizedBox(width: 12),
                                    Text(
                                      context.tr('my_network', selectedLanguage),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 8. Settings Navigation Menu (Stacked vertically, full width, darker vibrant colors)
                FadeInSlideWidget(
                  slideOffset: 26,
                  child: Column(
                    children: [
                      _buildFullWidthMenuCard(
                        title: context.tr('my_network', selectedLanguage),
                        subtitle: selectedLanguage == 'Hindi' ? 'अपनी टीम और नेटवर्क की कमाई देखें' : 'View your team & network earnings',
                        icon: Icons.people_outline_rounded,
                        iconColor: const Color(0xFF3F37C9), // Dark vibrant blue
                        iconBgColor: const Color(0xFFEEECFF),
                        onTap: () => context.push('/my_network'),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: context.tr('leaderboard', selectedLanguage),
                        subtitle: context.tr('leaderboard_desc', selectedLanguage),
                        icon: Icons.leaderboard_outlined,
                        iconColor: const Color(0xFF0077B6), // Dark vibrant cyan/blue
                        iconBgColor: const Color(0xFFE3F2FD),
                        onTap: () => _showLeaderboardBottomSheet(context, userName, totalEarned),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: 'EDIT PROFILE DETAILS',
                        subtitle: '${userData['name'] ?? 'User'} • @${userData['username'] ?? 'username'} • ${userData['gender'] ?? 'Gender'} • ${userData['city'] ?? 'City'}',
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF8A2BE2),
                        iconBgColor: const Color(0xFFF3E5F5),
                        trailing: const Icon(Icons.edit_rounded, size: 14, color: Colors.grey),
                        onTap: () => _showProfileDetailsUpdateDialog(context, userData),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: context.tr('upi_id', selectedLanguage),
                        subtitle: userData['upiId'] ?? (selectedLanguage == 'Hindi' ? 'सेट नहीं है' : 'Not Set'),
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF0F9D58), // Dark vibrant green
                        iconBgColor: const Color(0xFFE0F2F1),
                        trailing: const Icon(Icons.edit_rounded, size: 14, color: Colors.grey),
                        onTap: () => _showUpiUpdateDialog(context, userData['upiId']),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: 'PLAYGROUND BIO',
                        subtitle: userData['bio'] ?? (selectedLanguage == 'Hindi' ? 'कुछ लिखो...' : 'Add playground bio...'),
                        icon: Icons.assignment_outlined,
                        iconColor: const Color(0xFF9D4EDD), // Dark purple
                        iconBgColor: const Color(0xFFF3E5F5),
                        trailing: const Icon(Icons.edit_rounded, size: 14, color: Colors.grey),
                        onTap: () => _showBioUpdateDialog(context, userData['bio']),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: context.tr('language', selectedLanguage),
                        subtitle: context.tr('language_desc', selectedLanguage),
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF6F5EFA),
                        iconBgColor: const Color(0xFFEEECFF),
                        onTap: () => context.push('/language'),
                      ),
                      const SizedBox(height: 10),
                      _buildFullWidthMenuCard(
                        title: context.tr('help_support', selectedLanguage),
                        subtitle: context.tr('help_desc', selectedLanguage),
                        icon: Icons.support_agent_rounded,
                        iconColor: const Color(0xFF00796B), // Dark vibrant teal
                        iconBgColor: const Color(0xFFE0F7FA),
                        onTap: () => context.push('/support'),
                      ),
                      const SizedBox(height: 10),
                      _buildLogoutCard(context, ref),
                      const SizedBox(height: 10),
                      _buildDeleteAccountCard(context, ref),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub-widgets & UI Builders ---

  Widget _buildNotificationBell(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider).unreadCount;
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A3E9C).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF4A3AFF), size: 24),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildAchievementBadgeCard({
    required BuildContext context,
    required BadgeInfo badge,
    required bool isUnlocked,
    required bool isActive,
    required int totalEarned,
    required int prevTarget,
  }) {
    // Determine target label
    final targetLabel = badge.targetCoins >= 1000 ? '${badge.targetCoins ~/ 1000}K' : '${badge.targetCoins}';
    
    // Progress calculation for active badge
    final double badgeProgress = isActive 
        ? ((totalEarned - prevTarget) / (badge.targetCoins - prevTarget)).clamp(0.0, 1.0)
        : 0.0;
        
    return Container(
      width: 115, // Width increased to fit larger layouts
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isUnlocked || isActive ? Colors.white : const Color(0xFFF7F8FC).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? Colors.amber.withValues(alpha: 0.8) 
              : (isUnlocked ? badge.color.withValues(alpha: 0.2) : const Color(0xFFEFF0F6)),
          width: isActive ? 1.8 : 1.2,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Badge image size increased to 56 for superior visibility
              _buildBadgeImage(badge.imagePath, badge.fallbackIcon, badge.color, size: 56),
              if (!isUnlocked && !isActive)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, size: 8, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 13, // Font size slightly increased
              color: isUnlocked || isActive ? AppColors.textPrimary : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          
          if (isActive) ...[
            Text(
              '${totalEarned >= 1000 ? '${_formatNumber(totalEarned ~/ 1000)}K' : _formatNumber(totalEarned)} / $targetLabel Coins',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8.5,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: badgeProgress,
                minHeight: 3,
                backgroundColor: const Color(0xFFFFF7E6),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
              ),
            ),
          ] else ...[
            Text(
              '$targetLabel Coins',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
                color: isUnlocked ? badge.color : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            isUnlocked 
                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF06D6A0), size: 12)
                : Icon(Icons.lock_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 10),
          ]
        ],
      ),
    );
  }



  Future<void> _shareReferral(String referralCode, String appLink) async {
    try {
      final ByteData bytes = await rootBundle.load('assets/images/referral_share_banner.webp');
      final Uint8List list = bytes.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/referral_share_banner.png').create();
      await file.writeAsBytes(list);
      
      final String shareText = '🎮 Hey! Join SikkaPlay and earn real rewards playing games and watching reels! 💰\n\n'
          'Use my referral code: * $referralCode *\n\n'
          'Download the app now: $appLink';
          
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Invite Friends to SikkaPlay',
      );
    } catch (e) {
      debugPrint('Sharing failed: $e');
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    // Pop the bottom sheet immediately before opening the image picker
    // to prevent navigation stack corruption and black screens.
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      setState(() {
        _isUploadingAvatar = true;
      });

      final bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      try {
        final newAvatarUrl = await ref.read(userServiceProvider).updateProfilePicture(base64Image);
        if (newAvatarUrl != null) {
          if (mounted) {
            await ref.read(userProvider.notifier).fetchProfile();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload Error: $e'), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)),
          );
        }
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  void _showAvatarSelectionSheet() {
    final selectedLanguage = ref.read(languageProvider);
    final userData = ref.read(userProvider).userData ?? {};
    final userName = userData['name'] ?? context.tr('sikkaplay_user', selectedLanguage);
    String initials = 'SP';
    if (userName.isNotEmpty && userName != 'SikkaPlay User') {
      final parts = userName.trim().split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = userName.substring(0, userName.length > 1 ? 2 : 1).toUpperCase();
      }
    }

    String activeTab = 'Male';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('select_profile_avatar', selectedLanguage),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('choose_avatar_desc', selectedLanguage),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Use My Initials - Persistent Option Card
                  GestureDetector(
                    onTap: () {
                      _saveSelectedAvatar(0);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedAvatarIndex == 0
                            ? const Color(0xFF6F5EFA).withValues(alpha: 0.08)
                            : const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedAvatarIndex == 0
                              ? const Color(0xFF6F5EFA)
                              : const Color(0xFFEFF0F6),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedAvatarIndex == 0
                                  ? const Color(0xFF6F5EFA)
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedAvatarIndex == 0
                                    ? Colors.transparent
                                    : const Color(0xFFEFF0F6),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(
                                  color: _selectedAvatarIndex == 0 ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('use_my_initials', selectedLanguage),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('avatar_desc_initials', selectedLanguage),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedAvatarIndex == 0)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF6F5EFA),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  // Upload from Gallery Option
                  GestureDetector(
                    onTap: _pickAndUploadProfileImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0E7FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF6F5EFA),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload from Gallery', // TODO: Add translation if needed
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose a photo from your device',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isUploadingAvatar)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F5EFA)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Gender Tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              activeTab = 'Male';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 'Male'
                                  ? const Color(0xFF6F5EFA)
                                  : const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: activeTab == 'Male'
                                    ? const Color(0xFF6F5EFA)
                                    : const Color(0xFFEFF0F6),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                context.tr('male', selectedLanguage),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 'Male'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              activeTab = 'Female';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 'Female'
                                  ? const Color(0xFF6F5EFA)
                                  : const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: activeTab == 'Female'
                                    ? const Color(0xFF6F5EFA)
                                    : const Color(0xFFEFF0F6),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                context.tr('female', selectedLanguage),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 'Female'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 18),
                  
                  // Avatars Grid (3 columns)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, gridIndex) {
                      final targetAvatarIndex = activeTab == 'Male' ? gridIndex + 1 : gridIndex + 7;
                      final isSelected = _selectedAvatarIndex == targetAvatarIndex;
                      
                      final avatar = avatarOptions[targetAvatarIndex - 1];
                      final gradientColors = avatar['gradient'] as List<Color>;
                      final imagePath = avatar['image'] as String;
                      final fallbackIcon = avatar['fallbackIcon'] as IconData;

                      return GestureDetector(
                        onTap: () {
                          _saveSelectedAvatar(targetAvatarIndex);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6F5EFA) : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6F5EFA).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: ClipOval(
                              child: Image.asset(
                                imagePath,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  fallbackIcon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildFullWidthMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final selectedLanguage = ref.watch(languageProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3E9C).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(title, selectedLanguage),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(subtitle, selectedLanguage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(languageProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100.withValues(alpha: 0.8), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            await AuthService().logout();
            ref.invalidate(userProvider);
            ref.invalidate(homeProvider);
            if (context.mounted) {
              context.go('/login');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 18), // Darker red icon
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('logout', selectedLanguage),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: const Color(0xFFD32F2F), // Darker red text
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedLanguage == 'Hindi' ? 'अपने खाते से सुरक्षित रूप से लॉग आउट करें' : 'Log out safely from your account',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD32F2F)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(languageProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade900.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            _showDeleteConfirmationDialog(context, ref, selectedLanguage);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedLanguage == 'Hindi' ? 'खाता हटाएं' : 'Delete Account',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedLanguage == 'Hindi' ? 'अपना डेटा स्थायी रूप से हटाएं' : 'Permanently delete your data',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String selectedLanguage) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(
                selectedLanguage == 'Hindi' ? 'खाता हटाएं' : 'Delete Account',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
              ),
            ],
          ),
          content: Text(
            selectedLanguage == 'Hindi' 
              ? 'क्या आप वाकई अपना खाता हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती है और आपका सारा डेटा खो जाएगा।' 
              : 'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel', selectedLanguage), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await AuthService().deleteAccount();
                if (result['success'] == true) {
                  ref.invalidate(userProvider);
                  ref.invalidate(homeProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(selectedLanguage == 'Hindi' ? 'खाता सफलतापूर्वक हटा दिया गया' : 'Account deleted successfully')),
                    );
                    context.go('/login');
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Failed to delete account')),
                    );
                  }
                }
              },
              child: Text(selectedLanguage == 'Hindi' ? 'हटाएं' : 'Delete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUpiUpdateDialog(BuildContext context, String? currentUpi) {
    _upiController.text = currentUpi ?? '';
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E), // Match dark success dialog theme
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.tr('update_upi', selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: _upiController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: context.tr('enter_upi', selectedLanguage),
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel', selectedLanguage), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUpi = _upiController.text.trim();
                if (newUpi.isNotEmpty) {
                  Navigator.pop(context);
                  final success = await ref.read(userProvider.notifier).updateUpi(newUpi);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? context.tr('upi_updated_success', selectedLanguage) : context.tr('upi_updated_failed', selectedLanguage)),
                        backgroundColor: success ? AppColors.success : Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(selectedLanguage == 'Hindi' ? 'सुरक्षित करें' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showBioUpdateDialog(BuildContext context, String? currentBio) {
    final TextEditingController bioController = TextEditingController(text: currentBio ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Playground Bio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: bioController,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe yourself in a few words...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBio = bioController.text.trim();
                Navigator.pop(context);
                final res = await _playgroundService.updateBio(newBio);
                if (res['success'] == true) {
                  ref.read(userProvider.notifier).refresh();
                  if (context.mounted) {
                    GameNotifications.showCoinUpdate(context, 'Bio updated successfully!');
                  }
                } else {
                  if (context.mounted) {
                    GameNotifications.showCoinUpdate(context, res['error'] ?? 'Bio update failed');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDetailsUpdateDialog(BuildContext context, Map<String, dynamic> userData) {
    final TextEditingController nameController = TextEditingController(text: userData['name'] ?? '');
    final TextEditingController usernameController = TextEditingController(text: userData['username'] ?? '');
    final TextEditingController cityController = TextEditingController(text: userData['city'] ?? '');
    String selectedGender = (userData['gender'] ?? 'Male').toString();
    if (!['Male', 'Female', 'Other'].contains(selectedGender)) {
      if (selectedGender.toLowerCase() == 'female') selectedGender = 'Female';
      else if (selectedGender.toLowerCase() == 'other') selectedGender = 'Other';
      else selectedGender = 'Male';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Playground Username', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixText: '@ ',
                        prefixStyle: const TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold),
                        hintText: '3-15 alphanumeric chars',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButton<String>(
                        value: selectedGender,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2E),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: ['Male', 'Female', 'Other'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedGender = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('City', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your city',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newUsername = usernameController.text.trim();
                    final newCity = cityController.text.trim();
                    Navigator.pop(context);
                    final res = await ref.read(userProvider.notifier).updateProfileDetails(
                      name: newName.isNotEmpty ? newName : null,
                      username: newUsername.isNotEmpty ? newUsername : null,
                      gender: selectedGender,
                      city: newCity.isNotEmpty ? newCity : null,
                    );
                    if (res['success'] == true) {
                      if (context.mounted) {
                        GameNotifications.showCoinUpdate(context, 'Profile details updated successfully!');
                      }
                    } else {
                      if (context.mounted) {
                        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Profile update failed');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Stylish bottom sheet for Leaderboard since it doesn't have a standalone page
  void _showLeaderboardBottomSheet(BuildContext context, String currentUserName, int currentUserCoins) {
    final selectedLanguage = ref.read(languageProvider);
    final leaderboardFuture = ref.read(userServiceProvider).getLeaderboard();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF863BFF)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null || snapshot.data!['success'] != true) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('failed_load_leaderboard', selectedLanguage),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('check_connection_retry', selectedLanguage),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final List<dynamic> rawPlayers = data['leaderboard'] ?? [];
                final currentRankData = data['currentUserRank'];
                final int currentRank = currentRankData?['rank'] ?? 0;
                final currentUser = currentRankData?['user'];
                final String currentUserId = currentUser?['id'] ?? '';

                // Build players list and check if self is in top 20
                final List<Map<String, dynamic>> players = [];
                bool isSelfInTop = false;
                for (var p in rawPlayers) {
                  final map = Map<String, dynamic>.from(p);
                  if (map['id'] == currentUserId) {
                    map['isSelf'] = true;
                    isSelfInTop = true;
                  }
                  players.add(map);
                }

                return Column(
                  children: [
                    // Header Handle/Bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 26),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('weekly_leaderboard', selectedLanguage),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('leaderboard_promo', selectedLanguage),
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final rank = index + 1;
                          final isSelf = player['isSelf'] == true;
                          return _buildLeaderboardRow(context, player, rank, isSelf, selectedLanguage);
                        },
                      ),
                    ),
                    if (!isSelfInTop && currentUser != null) ...[
                      const Divider(height: 1, thickness: 1),
                      Container(
                        color: const Color(0xFFEEECFF),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: _buildLeaderboardRow(context, Map<String, dynamic>.from(currentUser), currentRank, true, selectedLanguage),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardRow(BuildContext context, Map<String, dynamic> player, int rank, bool isSelf, String selectedLanguage) {
    Color rankColor = Colors.grey.shade700;
    Widget rankWidget = Text(
      '#$rank',
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: rankColor,
      ),
    );

    if (rank == 1) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22);
    } else if (rank == 2) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFC0C0C0), size: 22);
    } else if (rank == 3) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: Color(0xFFCD7F32), size: 22);
    }

    String displayName = player['name'] as String? ?? '';
    if (displayName.trim().isEmpty) {
      final phone = player['phoneNumber'] as String? ?? '';
      if (phone.length > 4) {
        displayName = '${phone.substring(0, phone.length - 4)}****';
      } else {
        displayName = phone.isNotEmpty ? phone : context.tr('sikkaplay_user', selectedLanguage);
      }
    }

    final coins = player['totalEarned'] ?? player['coins'] ?? 0;
    final String avatarUrl = player['avatarUrl'] as String? ?? '';
    final String playerId = player['id'] as String? ?? '';
    final String username = player['username'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (username.isNotEmpty) {
            context.pop(); // close bottom sheet
            context.push('/playground/profile', extra: username);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelf ? const Color(0xFFEEECFF) : const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelf ? const Color(0xFF863BFF).withValues(alpha: 0.3) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: rankWidget),
              const SizedBox(width: 8),
              if (avatarUrl.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: avatarUrl.startsWith('http') 
                      ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                      : AssetImage(avatarUrl),
                )
              else
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE5E7EB),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.outfit(
                    fontWeight: isSelf ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13.5,
                    color: isSelf ? const Color(0xFF863BFF) : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(coins as num),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
