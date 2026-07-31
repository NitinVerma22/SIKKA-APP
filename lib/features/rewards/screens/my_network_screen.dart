import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';

class MyNetworkScreen extends ConsumerStatefulWidget {
  const MyNetworkScreen({super.key});

  @override
  ConsumerState<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends ConsumerState<MyNetworkScreen> {
  String _selectedLanguage = 'English';

  String _formatNumber(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _shareReferral(String referralCode, String appLink, String language) async {
    try {
      final ByteData bytes = await rootBundle.load('assets/images/referral_share_banner.webp');
      final Uint8List list = bytes.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/referral_share_banner.png').create();
      await file.writeAsBytes(list);
      
      final String shareText = language == 'Hindi'
          ? '🎮 अरे! SikkaPlay से जुड़ें और गेम खेलकर तथा रील्स देखकर वास्तविक पुरस्कार कमाएं! 💰\n\nमेरे रेफरल कोड का उपयोग करें: * $referralCode *\n\nअभी ऐप डाउनलोड करें: $appLink'
          : '🎮 Hey! Join SikkaPlay and earn real rewards playing games and watching reels! 💰\n\n'
              'Use my referral code: * $referralCode *\n\n'
              'Download the app now: $appLink';
          
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareText,
          subject: language == 'Hindi' ? 'सिक्काप्ले में दोस्तों को आमंत्रित करें' : 'Invite Friends to SikkaPlay',
        ),
      );
    } catch (e) {
      debugPrint('Sharing failed: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    _selectedLanguage = ref.watch(languageProvider);
    final userState = ref.watch(userProvider);
    final networkState = ref.watch(networkProvider);
    final userData = userState.userData ?? {};
    final networkBalance = networkState.referralBalance;
    final referralCode = userData['referralCode'] ?? 'LOADING...';
    
    final appConfigState = ref.watch(appConfigProvider);
    final appConfig = appConfigState.config;
    final minPlaytimeMins = appConfig?['refWithdrawMinPlaytimeMins'] ?? 3000;
    final minReferrals = appConfig?['refWithdrawMinReferrals'] ?? 2;
    final minPlaytimeHours = minPlaytimeMins / 60.0;

    // Real data integration
    final personalPlaytimeHours = networkState.personalPlaytime / 60.0;
    final activeReferrals = networkState.level1.length;
    final canWithdraw = personalPlaytimeHours >= minPlaytimeHours && activeReferrals >= minReferrals;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC), // Matching mockup background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('my_network', _selectedLanguage),
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEBF5), width: 1.5),
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
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                final appConfig = ref.read(appConfigProvider).config;
                final appLink = appConfig?['apkDownloadUrl'] ?? 'https://sikkaplay.com';
                _shareReferral(referralCode, appLink, _selectedLanguage);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEBEBF5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildImageWithFallback(
                    'assets/images/profile/referral_gift.webp',
                    22,
                    22,
                    const Icon(Icons.share_rounded, color: Color(0xFF863BFF), size: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: networkState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Referral Code Banner (Mockup style with floating coins & glassmorphic share button)
                  _buildReferralBanner(context, referralCode),
                  const SizedBox(height: 20),

                  // 2. Network Wallet & Withdraw Row (Side-by-side with locked/unlocked indicator)
                  _buildWalletRow(context, networkBalance, canWithdraw, personalPlaytimeHours, activeReferrals, minPlaytimeHours, minReferrals),
                  const SizedBox(height: 20),

                  // 3. Personal Playtime & Withdrawal Requirements Card
                  _buildRequirementsSection(personalPlaytimeHours.toInt(), activeReferrals, minPlaytimeHours.toInt(), minReferrals),
                  const SizedBox(height: 20),

                  // 4. My Referrals (Tree Structure or Empty State Mockup design)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF863BFF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFF863BFF), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('my_referrals_title', _selectedLanguage).replaceAll('{count}', '${networkState.totalTeam}'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (networkState.totalTeam == 0)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        GameNotifications.showCoinUpdate(context, context.tr('code_copied_toast', _selectedLanguage));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF863BFF).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.group_rounded, color: Color(0xFF863BFF), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('my_referrals_title', _selectedLanguage).replaceAll('{count}', '0'),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(text: context.tr('no_referrals_yet', _selectedLanguage)),
                                        TextSpan(
                                          text: context.tr('share_your_code', _selectedLanguage),
                                          style: const TextStyle(
                                            color: Color(0xFF863BFF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildTreeStructure(networkState),
                  const SizedBox(height: 24),

                  // 5. How it works (MLM Structure)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF863BFF).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.hub_rounded, color: Color(0xFF863BFF), size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('how_it_works_mlm', _selectedLanguage),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: const Color(0xFF863BFF).withValues(alpha: 0.4), size: 14),
                          const SizedBox(width: 4),
                          Icon(Icons.shape_line_rounded, color: const Color(0xFF863BFF).withValues(alpha: 0.3), size: 16),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context.tr('level1_title', _selectedLanguage),
                    context.tr('level1_desc', _selectedLanguage),
                    Icons.group_add_rounded,
                    const Color(0xFF4CAF50), // Nice Green
                    '10%',
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    context.tr('level2_title', _selectedLanguage),
                    context.tr('level2_desc', _selectedLanguage),
                    Icons.group_rounded,
                    const Color(0xFF2196F3), // Nice Blue
                    '5%',
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    context.tr('level3_title', _selectedLanguage),
                    context.tr('level3_desc', _selectedLanguage),
                    Icons.groups_3_rounded,
                    const Color(0xFFFF9800), // Nice Orange/Red
                    '2%',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildReferralBanner(BuildContext context, String referralCode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E6FF2), // Blue
            Color(0xFF863BFF), // Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF863BFF).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          // Left: Colored Users Icon instead of Image to prevent overflow and look modern
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), // Glassmorphic white
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.people_alt_rounded,
                color: Color(0xFFFFD600), // Vibrant Gold/Yellow colored icon
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Center: Referral code content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('your_referral_code', _selectedLanguage),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      referralCode,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        GameNotifications.showCoinUpdate(context, context.tr('code_copied_toast', _selectedLanguage));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: _selectedLanguage == 'Hindi' ? 'शेयर करें और कमाएं तक ' : 'Share to earn up to '),
                      const TextSpan(
                        text: '10,000',
                        style: TextStyle(
                          color: Color(0xFFFFD600),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: _selectedLanguage == 'Hindi' ? ' सिक्का प्रति मित्र!' : ' Sikka\nper friend!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Glassmorphic Share button
          GestureDetector(
            onTap: () {
              final appConfig = ref.read(appConfigProvider).config;
              final appLink = appConfig?['apkDownloadUrl'] ?? 'https://sikkaplay.com';
              _shareReferral(referralCode, appLink, _selectedLanguage);
            },
            child: Container(
              width: 58,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('share', _selectedLanguage),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildWalletRow(BuildContext context, int balance, bool canWithdraw, double playtimeHours, int activeReferrals, double minPlaytimeHours, int minReferrals) {
    final playtimeProgress = (playtimeHours / (minPlaytimeHours > 0 ? minPlaytimeHours : 1.0)).clamp(0.0, 1.0);
    final referralsProgress = (activeReferrals / (minReferrals > 0 ? minReferrals : 1.0)).clamp(0.0, 1.0);
    final overallProgress = (playtimeProgress + referralsProgress) / 2.0;

    return Row(
      children: [
        // Left Card: Balance
        Expanded(
          flex: 11,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('network_wallet_balance', _selectedLanguage),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD600),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatNumber(balance),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF863BFF),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (canWithdraw) {
                          GameNotifications.showCoinUpdate(context, context.tr('withdrawal_req_success', _selectedLanguage));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('withdrawal_req_reqs', _selectedLanguage)),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right Card: Unlock Status
        Expanded(
          flex: 10,
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 86, // aligns heights
            decoration: BoxDecoration(
              color: canWithdraw ? const Color(0xFFE8FDF5) : const Color(0xFFF7F4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: canWithdraw ? const Color(0xFF06D6A0).withValues(alpha: 0.2) : const Color(0xFF863BFF).withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: canWithdraw ? const Color(0xFF06D6A0).withValues(alpha: 0.12) : const Color(0xFF863BFF).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        canWithdraw ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: canWithdraw ? const Color(0xFF049E73) : const Color(0xFF863BFF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canWithdraw ? context.tr('unlocked', _selectedLanguage) : context.tr('locked', _selectedLanguage),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: canWithdraw ? const Color(0xFF049E73) : const Color(0xFF863BFF),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            canWithdraw ? context.tr('withdraw_ready', _selectedLanguage) : context.tr('needs_playtime_refs', _selectedLanguage),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      canWithdraw ? const Color(0xFF06D6A0) : const Color(0xFF863BFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection(int playtime, int referrals, int targetPlaytimeHours, int targetReferrals) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF863BFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF863BFF), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('withdrawal_requirements', _selectedLanguage),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementRow(
            _selectedLanguage == 'Hindi' 
                ? 'व्यक्तिगत खेल समय ($targetPlaytimeHours घंटे)' 
                : 'Personal Playtime (${targetPlaytimeHours}h)',
            playtime,
            targetPlaytimeHours,
          ),
          const SizedBox(height: 16),
          _buildRequirementRow(
            _selectedLanguage == 'Hindi' 
                ? 'सक्रिय रेफरल ($targetReferrals)' 
                : 'Active Referrals ($targetReferrals)',
            referrals,
            targetReferrals,
          ),
        ],
      ),
    );
  }

  Widget _buildTreeStructure(NetworkState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (state.level1.isNotEmpty)
            ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.people_alt_rounded, color: Colors.green),
              title: Text(context.tr('level1_referrals', _selectedLanguage), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              children: state.level1.map((u) => _buildUserCard(u, Colors.green)).toList(),
            ),
          if (state.level2.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.people_alt_rounded, color: Colors.blue),
              title: Text(context.tr('level2_referrals', _selectedLanguage), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              children: state.level2.map((u) => _buildUserCard(u, Colors.blue)).toList(),
            ),
          if (state.level3.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.people_alt_rounded, color: Colors.orange),
              title: Text(context.tr('level3_referrals', _selectedLanguage), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              children: state.level3.map((u) => _buildUserCard(u, Colors.orange)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user, Color color) {
    final joinedDate = user['createdAt'] != null ? user['createdAt'].toString().split('T').first : 'Unknown';
    final playtime = user['playtime'] ?? 0;
    final totalEarned = user['totalEarned'] ?? 0;
    final hours = (playtime / 60).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? (_selectedLanguage == 'Hindi' ? 'सिक्काप्ले यूजर' : 'SikkaPlay User'),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('joined', _selectedLanguage).replaceAll('{date}', '$joinedDate'),
                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.tr('earned_coins', _selectedLanguage).replaceAll('{coins}', '$totalEarned'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.yellowGlow),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('playtime_hours', _selectedLanguage).replaceAll('{hours}', '$hours'),
                style: GoogleFonts.outfit(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String title, int current, int target) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(
                    text: '$current',
                    style: TextStyle(
                      color: isComplete ? const Color(0xFF049E73) : const Color(0xFF863BFF),
                    ),
                  ),
                  const TextSpan(
                    text: ' / ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: '$target',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? const Color(0xFF06D6A0) : const Color(0xFF863BFF),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon, Color color, String percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              percentage,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
