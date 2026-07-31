import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'package:sikkaplay/main.dart';
import 'package:sikkaplay/routes/app_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/shared/widgets/ad_banner_widget.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';

class DailyCodeScreen extends ConsumerStatefulWidget {
  const DailyCodeScreen({super.key});

  @override
  ConsumerState<DailyCodeScreen> createState() => _DailyCodeScreenState();
}

class _DailyCodeScreenState extends ConsumerState<DailyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  String _timeRemaining = '24h 00m 00s';

  // Dynamic code info state
  bool _codeExists = false;
  String _codeName = '';
  int _coinsReward = 0;
  int _totalClaims = 0;
  int _maxClaims = 0;
  bool _hasClaimed = false;
  List<dynamic> _claimers = [];
  bool _loadingInfo = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _fetchCodeInfo();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _updateTime() {
    // Current UTC time
    final nowUtc = DateTime.now().toUtc();
    // Indian Standard Time (IST) is UTC+5:30
    final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));
    
    // Target is midnight IST of next day
    final tomorrowIst = DateTime(nowIst.year, nowIst.month, nowIst.day + 1);
    final difference = tomorrowIst.difference(nowIst);

    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    _timeRemaining = '${hours}h ${minutes}m ${seconds}s';
  }

  Future<void> _fetchCodeInfo() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '/user')}/daily-code/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _codeExists = data['codeExists'] ?? false;
              if (_codeExists) {
                _codeName = data['code'] ?? '';
                _coinsReward = data['coins'] ?? 0;
                _totalClaims = data['totalClaims'] ?? 0;
                _maxClaims = data['maxClaims'] ?? 0;
                _hasClaimed = data['hasClaimed'] ?? false;
                _claimers = data['claimers'] ?? [];
              } else {
                _claimers = [];
              }
              _loadingInfo = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching code info: $e');
      if (mounted) {
        setState(() {
          _loadingInfo = false;
        });
      }
    }
  }

  Future<void> _claimCode() async {
    final selectedLanguage = ref.read(languageProvider);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = context.tr('please_enter_code', selectedLanguage);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = context.tr('user_session_expired', selectedLanguage);
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '/user')}/daily-code/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': code,
        }),
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthService().logout();
        if (!mounted) return;
        final navigator = rootNavigatorKey.currentState;
        if (navigator != null) {
          while (navigator.canPop()) {
            navigator.pop();
          }
        }
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(response.statusCode == 403 ? Icons.block_rounded : Icons.logout_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['error'] ?? (response.statusCode == 403 ? context.tr('acc_suspended_err', selectedLanguage) : context.tr('session_expired_err', selectedLanguage)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
        return;
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final coinsEarned = data['coinsEarned'] as int;
        
        setState(() {
          _isLoading = false;
          _codeController.clear();
        });

        _fetchCodeInfo();

        _showCorrectCodeDialog(coinsEarned);
      } else {
        setState(() {
          _errorMessage = data['error'] ?? context.tr('failed_claim_code_retry', selectedLanguage);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr('network_failed_retry', selectedLanguage);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openInstagram() async {
    final selectedLanguage = ref.read(languageProvider);
    final Uri url = Uri.parse('https://www.instagram.com/sikkaplay');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('instagram_open_err', selectedLanguage))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('instagram_open_err', selectedLanguage))),
      );
    }
  }

  void _showCorrectCodeDialog(int coinsEarned) {
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CorrectCodeDialog(
        coinsEarned: coinsEarned,
        selectedLanguage: selectedLanguage,
        onWatchVideo: () {
          Navigator.of(context).pop();
          _showRealRewardedAd(coinsEarned);
        },
      ),
    );
  }

  void _showRealRewardedAd(int coinsEarned) {
    final selectedLanguage = ref.read(languageProvider);
    final userState = ref.read(userProvider);
    final userId = userState.userData?['id'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('user_session_expired', selectedLanguage))),
      );
      return;
    }

    final onCompleteClaim = () async {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
      await ref.read(userProvider.notifier).fetchProfile();
      ref.read(homeProvider.notifier).refresh();
      
      if (mounted) {
        _showRewardCreditedDialog(coinsEarned);
      }
    };

    final playRewardedOrSimulation = () {
      if (!AdService.instance.isRewardedAdLoaded()) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => FakeAdDialog(
            title: context.tr('code_of_the_day', selectedLanguage),
            message: context.tr('watch_video_claim_reward', selectedLanguage).replaceAll('{coins}', '$coinsEarned'),
            onComplete: onCompleteClaim,
          ),
        );
        AdService.instance.loadRewardedAd();
      } else {
        AdService.instance.showRewardedAd(
          context: context,
          userId: userId,
          onAdDismissed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('ad_closed_early_daily_code', selectedLanguage))),
            );
          },
          onUserEarnedReward: (reward) => onCompleteClaim(),
        );
      }
    };

    if (!AdService.instance.isRewardedAdLoaded()) {
      AdService.instance.loadRewardedAd();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (spinnerContext) {
          return _AdSpinnerDialog(
            selectedLanguage: selectedLanguage,
            onAdLoaded: () {
              Navigator.of(spinnerContext).pop();
              AdService.instance.showRewardedAd(
                context: context,
                userId: userId,
                onAdDismissed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('ad_closed_early_daily_code', selectedLanguage))),
                  );
                },
                onUserEarnedReward: (reward) => onCompleteClaim(),
              );
            },
            onTimeout: () {
              Navigator.of(spinnerContext).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FakeAdDialog(
                  title: context.tr('code_of_the_day', selectedLanguage),
                  message: context.tr('watch_video_claim_reward', selectedLanguage).replaceAll('{coins}', '$coinsEarned'),
                  onComplete: onCompleteClaim,
                ),
              );
            },
          );
        },
      );
    } else {
      playRewardedOrSimulation();
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
              context.tr('coins_credited_desc', selectedLanguage).replaceAll('{coins}', '$coinsEarned'),
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

  Widget _buildCoinStack(int count) {
    if (count == 1) {
      return const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 28);
    } else if (count == 2) {
      return const SizedBox(
        width: 38,
        height: 28,
        child: Stack(
          children: [
            Positioned(left: 0, child: Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 24)),
            Positioned(left: 12, child: Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 24)),
          ],
        ),
      );
    } else if (count == 3) {
      return const SizedBox(
        width: 50,
        height: 28,
        child: Stack(
          children: [
            Positioned(left: 0, child: Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 22)),
            Positioned(left: 12, child: Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 22)),
            Positioned(left: 24, child: Icon(Icons.monetization_on, color: Color(0xFFD97706), size: 22)),
          ],
        ),
      );
    } else {
      return const SizedBox(
        width: 50,
        height: 28,
        child: Stack(
          children: [
            Positioned(left: 0, bottom: 0, child: Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 22)),
            Positioned(left: 10, bottom: 1, child: Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 22)),
            Positioned(left: 20, bottom: 2, child: Icon(Icons.monetization_on, color: Color(0xFFD97706), size: 22)),
          ],
        ),
      );
    }
  }

  Widget _buildRewardCard({required String amount, required Widget coinsIcon, bool isPremium = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? const Color(0xFF863BFF) : const Color(0xFFEFF0F6),
          width: isPremium ? 1.5 : 1.0,
        ),
        boxShadow: isPremium ? [
          BoxShadow(
            color: const Color(0xFF863BFF).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isPremium)
            Positioned(
              top: -18,
              right: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF863BFF),
                  shape: BoxShape.circle,
                ),
                child: const Text('👑', style: TextStyle(fontSize: 8)),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              coinsIcon,
              const SizedBox(height: 8),
              Text(
                amount,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Coins',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard({
    required String name,
    required String amount,
    required String timeAgo,
    required String avatarText,
    required Color avatarBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarBgColor,
            child: Text(
              avatarText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 1),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF6D28D9)),
              ),
              const Text(
                'Coins',
                style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft slate background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('code_of_the_day', selectedLanguage),
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 14),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Banner
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 343 / 164,
                      child: Image.asset(
                        'assets/images/daily_code.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Claim Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, color: Color(0xFF863BFF), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            selectedLanguage == 'Hindi' ? 'आज का कोड दर्ज करें' : "ENTER TODAY'S CODE",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedLanguage == 'Hindi'
                            ? 'इनाम का दावा करने के लिए कोड सही ढंग से दर्ज करें'
                            : 'Enter the code correctly to claim your reward',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Field
                      TextField(
                        controller: _codeController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: selectedLanguage == 'Hindi' ? 'यहाँ कोड दर्ज करें' : 'Enter code here',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColors.textLight,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFEFF0F6), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFEFF0F6), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF863BFF), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Countdown Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.watch_later_outlined, color: Color(0xFF64748B), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            (selectedLanguage == 'Hindi' ? 'नया कोड ' : 'New code in ') + _timeRemaining,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gradient Claim Button
                      GestureDetector(
                        onTap: _isLoading ? null : _claimCode,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else ...[
                                const Icon(Icons.redeem_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  selectedLanguage == 'Hindi' ? 'इनाम का दावा करें' : 'CLAIM REWARD',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secure label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF22C55E), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '100% Secure & Safe',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Instagram Promo Banner
                GestureDetector(
                  onTap: _openInstagram,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE1306C), // Instagram Pink
                          Color(0xFFC13584), // Purple
                          Color(0xFF833AB4), // Deep Violet
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC13584).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Insta Logo Rounded Container
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedLanguage == 'Hindi' ? 'आज का कोड प्राप्त करें' : "GET TODAY'S CODE",
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFFD600), // Gold
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedLanguage == 'Hindi' ? 'हमें इंस्टाग्राम पर फॉलो करें' : 'Follow us on Instagram',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                selectedLanguage == 'Hindi' 
                                    ? 'दैनिक कोड, अपडेट और विशेष पुरस्कार प्राप्त करें!'
                                    : 'Get daily codes, updates and exclusive rewards!',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Follow Now Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedLanguage == 'Hindi' ? 'फॉलो करें' : 'Follow Now',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFC13584),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFC13584),
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. First Claimers / Glowing UI Section
                _buildFirstClaimersSection(selectedLanguage),
                const SizedBox(height: 20),

                // 6. Bottom Banner Ad
                const AdBannerWidget(placementName: 'daily_code'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstClaimersSection(String selectedLanguage) {
    final isHindi = selectedLanguage == 'Hindi';
    
    if (_loadingInfo) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Color(0xFF863BFF)),
        ),
      );
    }

    if (!_codeExists || _claimers.isEmpty) {
      return _GlowingPulsingCard(language: selectedLanguage);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD600), size: 18),
                const SizedBox(width: 8),
                Text(
                  isHindi ? 'आज के पहले दावेदार' : 'FIRST CLAIMERS OF TODAY',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (_maxClaims > 0)
              Text(
                isHindi ? 'दावा किया: $_totalClaims / $_maxClaims सीमा' : 'Claimed: $_totalClaims / $_maxClaims limit',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_claimers.length, (index) {
              final claimer = _claimers[index];
              final rank = claimer['rank'] as int;
              final name = claimer['name'] as String;
              final claimedAtStr = claimer['claimedAt'] as String;

              String timeStr = '';
              try {
                final claimedTime = DateTime.parse(claimedAtStr).toLocal();
                final diff = DateTime.now().difference(claimedTime);
                if (diff.inMinutes < 1) {
                  timeStr = isHindi ? 'अभी-अभी' : 'Just now';
                } else if (diff.inMinutes < 60) {
                  timeStr = isHindi ? '${diff.inMinutes} मिनट पहले' : '${diff.inMinutes}m ago';
                } else {
                  timeStr = isHindi ? '${diff.inHours} घंटे पहले' : '${diff.inHours}h ago';
                }
              } catch (_) {
                timeStr = '';
              }

              String medal = '🥇';
              Color rankColor = const Color(0xFFFFD700);
              if (rank == 2) {
                medal = '🥈';
                rankColor = const Color(0xFFC0C0C0);
              } else if (rank == 3) {
                medal = '🥉';
                rankColor = const Color(0xFFCD7F32);
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            medal,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHindi ? '${rank}वां स्थान' : 'Claimed #$rank',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index < _claimers.length - 1)
                    const Divider(color: Color(0xFFEFF0F6), height: 1, thickness: 1),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CorrectCodeDialog extends StatelessWidget {
  final int coinsEarned;
  final VoidCallback onWatchVideo;
  final String selectedLanguage;

  const _CorrectCodeDialog({
    required this.coinsEarned,
    required this.onWatchVideo,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('code_correct_title', selectedLanguage),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('code_correct_desc', selectedLanguage).replaceAll('{coins}', '$coinsEarned'),
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
                text: context.tr('watch_video_claim', selectedLanguage),
                icon: Icons.play_arrow_rounded,
                onTap: onWatchVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdSpinnerDialog extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback onAdLoaded;
  final VoidCallback onTimeout;

  const _AdSpinnerDialog({
    required this.selectedLanguage,
    required this.onAdLoaded,
    required this.onTimeout,
  });

  @override
  State<_AdSpinnerDialog> createState() => _AdSpinnerDialogState();
}

class _AdSpinnerDialogState extends State<_AdSpinnerDialog> {
  Timer? _timer;
  int _elapsedMs = 0;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || _resolved) {
        timer.cancel();
        return;
      }
      _elapsedMs += 200;
      if (AdService.instance.isRewardedAdLoaded()) {
        _resolved = true;
        timer.cancel();
        widget.onAdLoaded();
      } else if (_elapsedMs >= 3000) {
        _resolved = true;
        timer.cancel();
        widget.onTimeout();
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
    return Center(
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                widget.selectedLanguage == 'Hindi'
                    ? 'वीडियो विज्ञापन लोड हो रहा है...'
                    : 'Loading Video Ad...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowingPulsingCard extends StatefulWidget {
  final String language;
  const _GlowingPulsingCard({required this.language});

  @override
  State<_GlowingPulsingCard> createState() => _GlowingPulsingCardState();
}

class _GlowingPulsingCardState extends State<_GlowingPulsingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.language == 'Hindi';
    return AnimatedBuilder(
      animation: _glowAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF863BFF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFFFFD600),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'अभी तक किसी ने दावा नहीं किया! 🚀' : 'No one claimed till now! 🚀',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi 
                ? 'पहले दावा करें और अपना नाम यहाँ प्राप्त करें। यह सभी को दिखाया जाएगा! 🔥' 
                : 'You can claim and get your name here. It will be shown to all! 🔥',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E1B4B),
                Color(0xFF0F172A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF863BFF).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF863BFF).withValues(alpha: 0.25),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
