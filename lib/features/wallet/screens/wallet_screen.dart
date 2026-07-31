import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/features/wallet/controllers/wallet_controller.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _showReferralStats = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openWithdrawalFlow(BuildContext context, int targetBalance, String earningType) {
    final configState = ref.read(appConfigProvider);
    final minLimit = configState.config?['minWithdrawalLimit'] ?? 10000;
    final minRupees = minLimit ~/ 100;

    if (targetBalance < minLimit) {
      showDialog(
        context: context,
        builder: (dialogContext) {
        final selectedLanguage = ref.read(languageProvider);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🥺', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 20),
                Text(
                    selectedLanguage == 'Hindi' ? 'लगभग वहाँ!' : 'Almost There!',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedLanguage == 'Hindi'
                        ? 'पैसे निकालने के लिए आपको ${earningType == 'referral' ? 'रेफरल' : 'खुद की'} कमाई से न्यूनतम ${minLimit.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} सिक्का (₹$minRupees) की आवश्यकता है।\n\nअपने लक्ष्य तक पहुँचने के लिए सिक्का कमाते रहें!'
                        : 'You need a minimum of ${minLimit.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} Sikka (₹$minRupees) from ${earningType == 'referral' ? 'Referral' : 'Self'} Earning to withdraw.\n\nKeep earning Sikka to reach your goal!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    ),
                    child: Text(selectedLanguage == 'Hindi' ? 'समझ गया' : 'Got it', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }
      );
      return;
    }

    final List<Map<String, int>> withdrawalOptions = [
      {'rupees': minRupees, 'coins': minLimit},
      {'rupees': minRupees * 2, 'coins': minLimit * 2},
      {'rupees': minRupees * 3, 'coins': minLimit * 3},
      {'rupees': minRupees * 5, 'coins': minLimit * 5},
    ];

    final userData = ref.read(userProvider).userData ?? {};
    final savedUpiId = userData['upiId'] as String?;
    final savedName = userData['name'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: WithdrawalSheetContent(
            options: withdrawalOptions,
            balance: targetBalance,
            initialUpiId: savedUpiId,
            initialName: savedName,
            onWithdraw: (coinsAmount, upiId, name) async {
              if (savedUpiId == null || savedUpiId.isEmpty) {
                await ref.read(userProvider.notifier).updateUpi(upiId);
              }
              final success = await ref.read(homeProvider.notifier).requestWithdrawal(
                coinsAmount,
                upiId,
                name,
                earningType: earningType,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                if (success) {
                  _showSuccessSheet(context, coinsAmount ~/ 100);
                  ref.read(walletProvider.notifier).fetchWalletData();
                  ref.read(userProvider.notifier).refresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to request withdrawal. Please check your balance or UPI ID.')),
                  );
                }
              }
              return success;
            },
          ),
        );
      },
    );
  }

  void _showWithdrawalTypeSelector(BuildContext context, int balance, int referralEarning) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final selectedLanguage = ref.read(languageProvider);
        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                selectedLanguage == 'Hindi' ? 'निकासी प्रकार चुनें' : 'Select Withdrawal Type',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                selectedLanguage == 'Hindi' ? 'वह बैलेंस पूल चुनें जिससे आप पैसे निकालना चाहते हैं' : 'Choose the balance pool you want to withdraw from',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSizes.xl),
              // Option 1: Self Earning
              InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openWithdrawalFlow(context, balance, 'self');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedLanguage == 'Hindi' ? 'खुद की कमाई' : 'Self Earnings',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedLanguage == 'Hindi' ? 'उपलब्ध सिक्का' : 'Available Sikka'}: $balance',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Option 2: Referral Earning
              InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleReferralWithdrawalTap(context, referralEarning);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFFEC4899)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedLanguage == 'Hindi' ? 'रेफरल कमाई' : 'Referral Earnings',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedLanguage == 'Hindi' ? 'उपलब्ध सिक्का' : 'Available Sikka'}: $referralEarning',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        );
      },
    );
  }

  void _handleReferralWithdrawalTap(BuildContext context, int referralEarning) async {
    BuildContext? dialogContext;
    // Show loading dialog while fetching network stats
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) {
        dialogContext = dContext;
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );

    try {
      await ref.read(networkProvider.notifier).fetchNetwork();
    } catch (e) {
      // ignore
    } finally {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!); // Dismiss loading dialog using its own context
      }
    }

    final networkState = ref.read(networkProvider);
    final playtimeMinutes = networkState.personalPlaytime;
    final playtimeHours = playtimeMinutes / 60.0;
    final activeReferralsCount = networkState.level1.length;

    final appConfig = ref.read(appConfigProvider).config;
    final minPlaytimeMins = appConfig?['refWithdrawMinPlaytimeMins'] ?? 3000;
    final minReferrals = appConfig?['refWithdrawMinReferrals'] ?? 2;
    final minPlaytimeHours = minPlaytimeMins / 60.0;

    final isEligible = playtimeHours >= minPlaytimeHours && activeReferralsCount >= minReferrals;

    if (!isEligible) {
      if (context.mounted) {
        _showReferralIneligibilityDialog(context, playtimeHours, activeReferralsCount, minPlaytimeHours, minReferrals);
      }
    } else {
      if (context.mounted) {
        _openWithdrawalFlow(context, referralEarning, 'referral');
      }
    }
  }

  void _showReferralIneligibilityDialog(BuildContext context, double playtimeHours, int activeReferrals, double minPlaytimeHours, int minReferrals) {
    final playtimeProgress = (playtimeHours / (minPlaytimeHours > 0 ? minPlaytimeHours : 1.0)).clamp(0.0, 1.0);
    final referralsProgress = (activeReferrals / (minReferrals > 0 ? minReferrals : 1.0)).clamp(0.0, 1.0);

    final playtimeNeeded = minPlaytimeHours - playtimeHours;
    final referralsNeeded = minReferrals - activeReferrals;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final selectedLanguage = ref.read(languageProvider);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFEF4444), size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    selectedLanguage == 'Hindi' ? 'निकासी लॉक है' : 'Withdrawal Locked',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    selectedLanguage == 'Hindi'
                        ? 'रेफरल कमाई निकालने के लिए, आपको खेल का समय और सक्रिय रेफरल मानदंडों को पूरा करना होगा।'
                        : 'To withdraw referral earnings, you must meet the play time and active referral criteria.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Playtime progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          playtimeHours >= minPlaytimeHours ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: playtimeHours >= minPlaytimeHours ? const Color(0xFF22C55E) : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedLanguage == 'Hindi'
                              ? 'व्यक्तिगत खेल समय (${minPlaytimeHours.toStringAsFixed(0)} घंटे)'
                              : 'Personal Playtime (${minPlaytimeHours.toStringAsFixed(0)}h)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text(
                      '${playtimeHours.toStringAsFixed(1)}h / ${minPlaytimeHours.toStringAsFixed(0)}h',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: playtimeHours >= minPlaytimeHours ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: playtimeProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      playtimeHours >= minPlaytimeHours ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                if (playtimeHours < minPlaytimeHours) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedLanguage == 'Hindi'
                        ? 'खेल लक्ष्य तक पहुँचने के लिए ${playtimeNeeded.toStringAsFixed(1)} घंटे शेष हैं'
                        : '${playtimeNeeded.toStringAsFixed(1)} hours remaining to reach play target',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 20),

                // 2. Referrals progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          activeReferrals >= minReferrals ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: activeReferrals >= minReferrals ? const Color(0xFF22C55E) : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedLanguage == 'Hindi' ? 'सक्रिय रेफरल ($minReferrals)' : 'Active Referrals ($minReferrals)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text(
                      '$activeReferrals / $minReferrals',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: activeReferrals >= minReferrals ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: referralsProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      activeReferrals >= minReferrals ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                if (activeReferrals < minReferrals) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedLanguage == 'Hindi'
                        ? 'अनलॉक करने के लिए $referralsNeeded और रेफरल की आवश्यकता है'
                        : '$referralsNeeded more referral(s) needed to unlock',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(selectedLanguage == 'Hindi' ? 'समझ गया' : 'Got it', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (activeReferrals < minReferrals) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.go('/my_network');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(selectedLanguage == 'Hindi' ? 'दोस्तों को आमंत्रित करें' : 'Invite Friends', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showSuccessSheet(BuildContext context, int rupees) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) {
        final selectedLanguage = ref.read(languageProvider);
        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 64),
              const SizedBox(height: AppSizes.md),
              Text(
                selectedLanguage == 'Hindi' ? 'निकासी शुरू की गई!' : 'Withdrawal Initiated!',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                selectedLanguage == 'Hindi'
                    ? '₹$rupees का ट्रांसफर प्रोसेस किया जा रहा है और 24 घंटे के भीतर आपके खाते में दिखाई देगा। वर्तमान स्थिति लंबित स्वीकृति है।'
                    : 'Transfer of ₹$rupees is being processed and will reflect in your account within 24 hours. Status is currently Pending Approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSizes.xl),
              PremiumButton(
                text: selectedLanguage == 'Hindi' ? 'हो गया' : 'Done',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        );
      },
    );
  }

  IconData _getTxIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('withdraw')) return Icons.outbox_rounded;
    if (lowercaseTitle.contains('link') || lowercaseTitle.contains('visit')) return Icons.link_rounded;
    if (lowercaseTitle.contains('survey') || lowercaseTitle.contains('pollfish')) return Icons.star_outline_rounded;
    if (lowercaseTitle.contains('streak') || lowercaseTitle.contains('checkin')) return Icons.water_drop_outlined;
    return Icons.add_circle_outline_rounded;
  }

  Color _getTxColor(String type) {
    return type == 'withdrawal' ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
  }

  Color _getTxBgColor(String type) {
    return type == 'withdrawal' ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    final walletState = ref.watch(walletProvider);
    final walletStats = walletState.stats;
    final transactions = walletState.transactions;
    final isLoadingStats = walletStats == null && walletState.isLoading;
    final isLoadingTransactions = transactions.isEmpty && walletState.isLoading;

    final homeState = ref.watch(homeProvider);
    final userState = ref.watch(userProvider);
    final userData = userState.userData ?? {};
    final balance = userData['balance'] ?? homeState.balance;
    final totalEarning = userData['totalEarned'] ?? homeState.totalEarning;
    final referralEarning = userData['referralBalance'] ?? homeState.referralEarning;
    final withdrawalAmount = userData['withdrawalAmount'] ?? homeState.withdrawalAmount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC), // Slate-50 top
              Color(0xFFF1F5F9), // Slate-100 bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Wallet Balance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedLanguage == 'Hindi' ? 'मेरा वॉलेट' : 'My Wallet',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedLanguage == 'Hindi' ? 'अपनी कमाई और लेन-देन ट्रैक करें' : 'Track your earnings and transactions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Wallet Balance card with solid purple gradient
                      GestureDetector(
                        onTap: () => context.push('/wallet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFFEF4444), // Red wallet icon matching mockup
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr('wallet', selectedLanguage),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${balance + referralEarning}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.monetization_on,
                                        color: AppColors.yellowGlow,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  FadeInSlideWidget(
                    slideOffset: 15,
                    child: Column(
                      children: [
                        // Main stats grid (Row 1)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'कुल कमाई' : 'Total Earning',
                                amount: totalEarning + referralEarning,
                                color: const Color(0xFF22C55E), // Green
                                icon: Icons.attach_money_rounded,
                                upwardTrend: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'उपलब्ध बैलेंस' : 'Available Balance',
                                amount: balance + referralEarning,
                                color: const Color(0xFF8B5CF6), // Purple
                                icon: Icons.wallet_rounded,
                                upwardTrend: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Main stats grid (Row 2 - Split Earnings)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'खुद की कमाई' : 'Self Earning',
                                amount: totalEarning,
                                color: const Color(0xFF3B82F6), // Blue
                                icon: Icons.person_rounded,
                                upwardTrend: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'रेफरल कमाई' : 'Referral Earning',
                                amount: referralEarning,
                                color: const Color(0xFFEC4899), // Pink
                                icon: Icons.people_alt_rounded,
                                upwardTrend: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Main stats grid (Row 3)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'कुल निकासी' : 'Total Withdrawn',
                                amount: withdrawalAmount,
                                color: const Color(0xFFEF4444), // Red
                                icon: Icons.arrow_downward_rounded,
                                upwardTrend: false,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStatCard(
                                title: selectedLanguage == 'Hindi' ? 'लंबित निकासी' : 'Pending Withdrawal',
                                amount: walletStats?['pendingWithdrawal'] ?? 0,
                                color: const Color(0xFFF97316), // Orange
                                icon: Icons.watch_later_rounded,
                                upwardTrend: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Full-width Withdraw Cash action button
                        GestureDetector(
                          onTap: () => _showWithdrawalTypeSelector(context, balance, referralEarning),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 20), // Left spacer to center the core content
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Color(0xFF6D28D9),
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedLanguage == 'Hindi' ? 'पैसे निकालें' : 'Withdraw Cash',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tabs bar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0), // Slate-200
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _showReferralStats = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_showReferralStats ? const Color(0xFF7C3AED) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          color: !_showReferralStats ? Colors.white : const Color(0xFF64748B),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          selectedLanguage == 'Hindi' ? 'खुद की कमाई' : 'Self Earning',
                                          style: TextStyle(
                                            color: !_showReferralStats ? Colors.white : const Color(0xFF64748B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _showReferralStats = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _showReferralStats ? const Color(0xFF7C3AED) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_alt_rounded,
                                          color: _showReferralStats ? Colors.white : const Color(0xFF64748B),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          selectedLanguage == 'Hindi' ? 'रेफरल कमाई' : 'Referral Earning',
                                          style: TextStyle(
                                            color: _showReferralStats ? Colors.white : const Color(0xFF64748B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time-period Stats Grid (2x2)
                        if (isLoadingStats)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (walletStats != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildPeriodCard(
                                  title: selectedLanguage == 'Hindi' ? 'आज' : 'Today',
                                  amount: walletStats[_showReferralStats ? 'referral' : 'self']['today'] ?? 0,
                                  color: const Color(0xFF22C55E),
                                  bgIconColor: const Color(0xFFDCFCE7),
                                  icon: Icons.today_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildPeriodCard(
                                  title: selectedLanguage == 'Hindi' ? 'कल' : 'Yesterday',
                                  amount: walletStats[_showReferralStats ? 'referral' : 'self']['yesterday'] ?? 0,
                                  color: const Color(0xFF8B5CF6),
                                  bgIconColor: const Color(0xFFF3E8FF),
                                  icon: Icons.calendar_month_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPeriodCard(
                                  title: selectedLanguage == 'Hindi' ? 'साप्ताहिक' : 'Weekly',
                                  amount: walletStats[_showReferralStats ? 'referral' : 'self']['weekly'] ?? 0,
                                  color: const Color(0xFF3B82F6),
                                  bgIconColor: const Color(0xFFE0F2FE),
                                  icon: Icons.bar_chart_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildPeriodCard(
                                  title: selectedLanguage == 'Hindi' ? 'मासिक' : 'Monthly',
                                  amount: walletStats[_showReferralStats ? 'referral' : 'self']['monthly'] ?? 0,
                                  color: const Color(0xFFEC4899),
                                  bgIconColor: const Color(0xFFFCE7F3),
                                  icon: Icons.pie_chart_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('recent_transactions', selectedLanguage),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/wallet/transactions'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          children: [
                            Text(
                              context.tr('view_all', selectedLanguage),
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF7C3AED),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Transactions List
                  isLoadingTransactions
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isEarning = tx['type'] == 'earning';
                            final txTitle = tx['title'] ?? 'Transaction';
                            final txAmount = tx['rewardAmount'] ?? 0;
                            final txTime = tx['timeAgo'] ?? 'Recent';
                            final txStatus = tx['status'] ?? 'Completed';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getTxBgColor(tx['type']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getTxIcon(txTitle),
                                      color: _getTxColor(tx['type']),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          txTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              txTime,
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                            ),
                                            if (!isEarning) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: txStatus == 'Pending Approval' || txStatus == 'Pending'
                                                      ? const Color(0xFFFFF7ED)
                                                      : const Color(0xFFF0FDF4),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  txStatus,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: txStatus == 'Pending Approval' || txStatus == 'Pending'
                                                        ? const Color(0xFFF97316)
                                                        : const Color(0xFF16A34A),
                                                  ),
                                                ),
                                              )
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      if (isEarning) ...[
                                        const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 14),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        '${isEarning ? "+" : "-"}$txAmount',
                                        style: TextStyle(
                                          color: isEarning ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build slim vertical bars representing trend
  Widget _buildSlimBar({required double height, required double opacity, required Color color}) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Helper to build stats cards
  Widget _buildStatCard({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
    required bool upwardTrend,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.0), // slim color-matched border
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04), // soft color-matched border shadow
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '$amount',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: upwardTrend
                      ? [
                          _buildSlimBar(height: 8, opacity: 0.3, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 14, opacity: 0.5, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 11, opacity: 0.7, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 20, opacity: 1.0, color: color),
                        ]
                      : [
                          _buildSlimBar(height: 20, opacity: 1.0, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 11, opacity: 0.7, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 14, opacity: 0.5, color: color),
                          const SizedBox(width: 3),
                          _buildSlimBar(height: 8, opacity: 0.3, color: color),
                        ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build period earning grid cards
  Widget _buildPeriodCard({
    required String title,
    required int amount,
    required Color color,
    required Color bgIconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.0), // slim color-matched border
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03), // very soft color-matched border shadow
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amount',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

class WithdrawalSheetContent extends StatefulWidget {
  final List<Map<String, int>> options;
  final int balance;
  final String? initialUpiId;
  final String? initialName;
  final Future<bool> Function(int coinsAmount, String upiId, String name) onWithdraw;

  const WithdrawalSheetContent({
    super.key,
    required this.options,
    required this.balance,
    this.initialUpiId,
    this.initialName,
    required this.onWithdraw,
  });

  @override
  State<WithdrawalSheetContent> createState() => _WithdrawalSheetContentState();
}

class _WithdrawalSheetContentState extends State<WithdrawalSheetContent> {
  int? _selectedOptionIndex;
  final _upiController = TextEditingController();
  final _nameController = TextEditingController();
  final _manualCoinsController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _upiController.text = widget.initialUpiId ?? '';
    _nameController.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _upiController.dispose();
    _nameController.dispose();
    _manualCoinsController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_isProcessing) return;

    int amountCoins = 0;
    if (_selectedOptionIndex != null) {
      amountCoins = widget.options[_selectedOptionIndex!]['coins']!;
    } else {
      final manualVal = _manualCoinsController.text.trim();
      if (manualVal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or enter an amount to withdraw')));
        return;
      }
      amountCoins = int.tryParse(manualVal) ?? 0;
    }

    final minLimit = widget.options.first['coins']!; // First option is minLimit
    if (amountCoins < minLimit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum withdrawal is $minLimit coins')));
      return;
    }

    if (amountCoins > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    if (_upiController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid UPI ID and Name')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onWithdraw(
        amountCoins,
        _upiController.text.trim(),
        _nameController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSavedUpi = widget.initialUpiId != null && widget.initialUpiId!.isNotEmpty;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Withdraw to UPI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: AppSizes.md),
            const Text('Select Amount', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final isSelected = _selectedOptionIndex == idx;
                final canAfford = widget.balance >= opt['coins']!;
                final isClickable = canAfford && !_isProcessing;

                return GestureDetector(
                  onTap: isClickable ? () {
                    setState(() {
                      _selectedOptionIndex = idx;
                      _manualCoinsController.text = opt['coins'].toString();
                    });
                  } : null,
                  child: Opacity(
                    opacity: isClickable ? 1.0 : 0.5,
                    child: Container(
                      width: (MediaQuery.of(context).size.width - AppSizes.lg * 2 - 8) / 2,
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isClickable ? Colors.white : AppColors.background),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isClickable ? AppColors.borderLight : Colors.transparent),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('₹${opt['rupees']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 12),
                              const SizedBox(width: 2),
                              Text('${opt['coins']} Coins', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.md),
            const Text('Or Enter Manual Amount', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _manualCoinsController,
              enabled: !_isProcessing,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Sikka Coins',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide.none),
                suffixText: 'Coins',
                prefixIcon: const Icon(Icons.monetization_on, color: AppColors.yellowGlow),
              ),
              onChanged: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _selectedOptionIndex = null;
                  });
                }
              },
            ),
            const SizedBox(height: AppSizes.lg),
            const Text('UPI Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _nameController,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                hintText: 'Account Holder Name',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _upiController,
              readOnly: hasSavedUpi || _isProcessing,
              decoration: InputDecoration(
                hintText: 'UPI ID (e.g. name@okhdfcbank)',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide.none),
                suffixIcon: hasSavedUpi ? const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20) : null,
              ),
            ),
            if (hasSavedUpi) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'If you want to change UPI ID then go to profile for editing',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.xl),
            PremiumButton(
              text: _isProcessing ? 'Processing' : 'Submit Request',
              isLoading: _isProcessing,
              onTap: _isProcessing ? null : _submit,
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
