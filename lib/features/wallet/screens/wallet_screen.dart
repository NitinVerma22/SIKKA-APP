import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/user/user_service.dart';
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

  bool _isLoadingOptions = true;
  bool _showWithdrawalPackages = true;
  final List<Map<String, dynamic>> _dynamicSelfOptions = [];
  final List<Map<String, dynamic>> _dynamicReferralOptions = [];
  String _selfWithdrawalNotice = '';
  String _referralWithdrawalNotice = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletData();
      _loadWithdrawalOptions();
    });
  }

  Future<void> _loadWithdrawalOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });
    try {
      final res = await UserService().getWithdrawalOptions();
      if (res != null && res['success'] == true) {
        final List<dynamic> rawOptions = res['options'] ?? [];
        _selfWithdrawalNotice = res['selfWithdrawalNotice'] as String? ?? '';
        _referralWithdrawalNotice = res['referralWithdrawalNotice'] as String? ?? '';
        _showWithdrawalPackages = res['showWithdrawalPackages'] as bool? ?? true;

        _dynamicSelfOptions.clear();
        _dynamicReferralOptions.clear();

        for (final opt in rawOptions) {
          final mapped = {
            'id': opt['id'] as String,
            'coins': opt['coins'] as int,
            'baseRupees': opt['baseRupees'] as int,
            'bonusRupees': opt['bonusRupees'] as int,
            'totalRupees': opt['totalRupees'] as int,
            'netUpi': opt['netUpi'] as int,
            'cashbackCoins': opt['cashbackCoins'] as int,
            'badge': opt['badge'] as String? ?? '',
            'tagline': opt['tagline'] as String? ?? '',
            'color': _getColor(opt['color'] as String? ?? '#6366F1'),
            'buttonColor': _getColor(opt['buttonColor'] as String? ?? '#4F46E5'),
            'lightBg': _getColor(opt['lightBg'] as String? ?? '#EEF2FF'),
            'icon': _getIconData(opt['iconName'] as String? ?? 'account_balance_wallet_rounded'),
          };

          if (opt['earningType'] == 'self') {
            _dynamicSelfOptions.add(mapped);
          } else {
            _dynamicReferralOptions.add(mapped);
          }
        }
      }
    } catch (e) {
      print('Error loading withdrawal options: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Color _getColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'savings_rounded':
        return Icons.savings_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openWithdrawalFlow(BuildContext context, int targetBalance, String earningType) {
    final List<Map<String, dynamic>> withdrawalOptions = earningType == 'self'
        ? _dynamicSelfOptions
        : _dynamicReferralOptions;

    final String notice = earningType == 'self'
        ? _selfWithdrawalNotice
        : _referralWithdrawalNotice;

    final userData = ref.read(userProvider).userData ?? {};
    final savedUpiId = userData['upiId'] as String?;
    final savedName = userData['name'] as String?;

    final appConfig = ref.read(appConfigProvider).config;
    final minLimit = appConfig?['minWithdrawalLimit'] as int? ?? 5000;

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
            earningType: earningType,
            initialUpiId: savedUpiId,
            initialName: savedName,
            minWithdrawalLimit: minLimit,
            withdrawalNotice: notice,
            showWithdrawalPackages: _showWithdrawalPackages,
            onWithdraw: (coinsAmount, netRupees, cashbackCoins, upiId, name, optionId) async {
              if (savedUpiId == null || savedUpiId.isEmpty) {
                await ref.read(userProvider.notifier).updateUpi(upiId);
              }
              final success = await ref.read(homeProvider.notifier).requestWithdrawal(
                coinsAmount,
                upiId,
                name,
                earningType: earningType,
                optionId: optionId,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                if (success) {
                  _showSuccessSheet(context, netRupees, cashbackCoins);
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

  void _showSuccessSheet(BuildContext context, int rupees, int cashbackCoins) {
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
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 64),
              const SizedBox(height: AppSizes.md),
              Text(
                selectedLanguage == 'Hindi' ? 'निकासी प्रक्रिया शुरू की गई!' : 'Withdrawal Initiated! 🎉',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                selectedLanguage == 'Hindi'
                    ? '₹$rupees का UPI ट्रांसफर प्रोसेस किया जा रहा hai aur 24 ghante me account me aayega.'
                    : 'Transfer of ₹$rupees is being processed to your UPI account within 24 hours.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
               if (cashbackCoins > 0) ...[
                 const SizedBox(height: 16),
                 // Cashback Banner Card
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: const Color(0xFFFEF3C7),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 28),
                       const SizedBox(width: 10),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               selectedLanguage == 'Hindi'
                                   ? '+$cashbackCoins सिक्के (15% रिफंड) रिफंड हुए!'
                                   : '+$cashbackCoins Sikka Coins Refunded! 🎁',
                               style: GoogleFonts.outfit(
                                 color: const Color(0xFF92400E),
                                 fontWeight: FontWeight.bold,
                                 fontSize: 13,
                               ),
                             ),
                             Text(
                               selectedLanguage == 'Hindi'
                                   ? '15% मोटिवेशन बोनस तुरंत आपके सिक्के वॉलेट में क्रेडिट हो गया है!'
                                   : '15% Motivation CashBack credited back into your Sikka Wallet!',
                               style: GoogleFonts.outfit(
                                 color: const Color(0xFFB45309),
                                 fontSize: 11,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
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
  final List<Map<String, dynamic>> options;
  final int balance;
  final String earningType;
  final String? initialUpiId;
  final String? initialName;
  final int minWithdrawalLimit;
  final String withdrawalNotice;
  final bool showWithdrawalPackages;
  final Future<bool> Function(int coinsAmount, int netRupees, int cashbackCoins, String upiId, String name, String? optionId) onWithdraw;

  const WithdrawalSheetContent({
    super.key,
    required this.options,
    required this.balance,
    required this.earningType,
    this.initialUpiId,
    this.initialName,
    required this.minWithdrawalLimit,
    required this.withdrawalNotice,
    required this.showWithdrawalPackages,
    required this.onWithdraw,
  });

  @override
  State<WithdrawalSheetContent> createState() => _WithdrawalSheetContentState();
}

class _WithdrawalSheetContentState extends State<WithdrawalSheetContent> {
  int? _selectedOptionIndex = 0; // Default first option
  final _upiController = TextEditingController();
  final _nameController = TextEditingController();
  final _manualCoinsController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _upiController.text = widget.initialUpiId ?? '';
    _nameController.text = widget.initialName ?? '';
    if (widget.options.isEmpty || !widget.showWithdrawalPackages) {
      _selectedOptionIndex = null;
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _nameController.dispose();
    _manualCoinsController.dispose();
    super.dispose();
  }

  void _showEditUpiDialog() {
    final tempUpiController = TextEditingController(text: _upiController.text);
    final tempNameController = TextEditingController(
      text: _nameController.text.isNotEmpty
          ? _nameController.text
          : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : ''),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Enter UPI & Name Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempNameController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tempUpiController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                  hintText: 'e.g. 9876543210@paytm / user@upi',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _nameController.text = tempNameController.text.trim();
                  _upiController.text = tempUpiController.text.trim();
                });
                Navigator.pop(dialogCtx);
              },
              child: Text('Save Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (_isProcessing) return;

    int amountCoins = 0;
    int totalRupees = 0;
    int netRupees = 0;
    int cashbackCoins = 0;
    String? selectedOptionId;

    if (_selectedOptionIndex != null && widget.options.isNotEmpty && widget.showWithdrawalPackages) {
      final opt = widget.options[_selectedOptionIndex!];
      selectedOptionId = opt['id'] as String?;
      amountCoins = opt['coins'] as int;
      totalRupees = opt['totalRupees'] as int;
      netRupees = opt['netUpi'] as int;
      cashbackCoins = opt['cashbackCoins'] as int;
    } else {
      final manualVal = _manualCoinsController.text.trim();
      if (manualVal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an option or enter coins')));
        return;
      }
      amountCoins = int.tryParse(manualVal) ?? 0;
      if (amountCoins < widget.minWithdrawalLimit) {
        final rupeesLimit = widget.minWithdrawalLimit ~/ 1000;
        final formattedLimit = widget.minWithdrawalLimit.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Minimum withdrawal limit is $formattedLimit Coins (₹$rupeesLimit)')));
        return;
      }
      totalRupees = amountCoins ~/ 1000; // 1,000 Coins = ₹1
      final feeRupees = (totalRupees * 0.30).round();
      netRupees = totalRupees - feeRupees;
      cashbackCoins = (amountCoins * 0.15).round();
    }

    if (amountCoins > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    final upiId = _upiController.text.trim();
    if (upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid UPI ID before proceeding'),
        backgroundColor: Colors.redAccent,
      ));
      _showEditUpiDialog();
      return;
    }

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Sikka User');

    final feeRupees = totalRupees - netRupees;
    _showReceiptModal(amountCoins, totalRupees, feeRupees, netRupees, cashbackCoins, upiId, name, selectedOptionId);
  }

  void _showReceiptModal(int coins, int totalRupees, int feeRupees, int netRupees, int cashbackCoins, String upiId, String name, String? optionId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 16),
              Text(
                'Withdrawal Summary Receipt',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Requested Value:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text('$coins Coins (₹$totalRupees)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('30% Transaction Fee:', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('- ₹$feeRupees', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET UPI PAYOUT:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        Text('₹$netRupees', style: GoogleFonts.orbitron(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF22C55E))),
                      ],
                    ),
                     if (cashbackCoins > 0) ...[
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: const Color(0xFFFEF3C7),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Row(
                           children: [
                             const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 20),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 '🎁 +$cashbackCoins Coins (15% CashBack) will be credited back into your wallet!',
                                 style: GoogleFonts.outfit(color: const Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.bold),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PremiumButton(
                text: 'CONFIRM & TRANSFER',
                onTap: () {
                  Navigator.pop(modalContext);
                  _executeFinalWithdraw(coins, netRupees, cashbackCoins, upiId, name, optionId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeFinalWithdraw(int coins, int netRupees, int cashbackCoins, String upiId, String name, String? optionId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onWithdraw(coins, netRupees, cashbackCoins, upiId, name, optionId);
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('PHONE_VERIFICATION_REQUIRED')) { Navigator.of(context).pop(); context.push('/link-phone'); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.withdrawalNotice.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdrawal Notice',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.withdrawalNotice,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFB91C1C),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (widget.options.isEmpty && widget.withdrawalNotice.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Packages Available',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'There are no withdrawal options configured right now. Please check back later.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFB45309),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Purple Header Banner: Conversion Rate 1,000 Coins = ₹1
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4DFF), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4DFF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversion Rate',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '1,000 Coins = ₹1',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Minimum Limit: ${widget.minWithdrawalLimit.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} Coins (₹${widget.minWithdrawalLimit ~/ 1000})',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (widget.showWithdrawalPackages && widget.earningType == 'self' && widget.options.isNotEmpty) ...[
              // 2. Yellow Special Offers One-Time Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special offers for first withdrawal only',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'These offers are one-time only. You can claim each offer only once.',
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ONE-TIME\nOFFER',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            if (widget.options.isNotEmpty && widget.showWithdrawalPackages) ...[
              // 3. Section Title
              Text(
                'Select Withdrawal Amount (${widget.earningType == 'self' ? 'Self Earning' : 'Referral Earning'})',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              // 4. Horizontal Scroll Cards (3 Vertical Cards)
              SizedBox(
                height: 380,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.options.length,
                  itemBuilder: (context, idx) {
                    final opt = widget.options[idx];
                    final isSelected = _selectedOptionIndex == idx;
                    final Color cardColor = opt['color'] as Color;
                    final Color buttonColor = opt['buttonColor'] as Color;
                    final IconData cardIcon = opt['icon'] as IconData;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOptionIndex = idx;
                          _manualCoinsController.clear();
                        });
                      },
                      child: Container(
                        width: 250,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? buttonColor : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? buttonColor.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Ribbon Tag
                            if (opt['badge'].toString().isNotEmpty)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    opt['badge'].toString(),
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Graphic Icon Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: buttonColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cardIcon, color: buttonColor, size: 32),
                            ),
                            const SizedBox(height: 12),

                            // Coins Amount Title
                            Text(
                              opt['coins'].toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                              style: GoogleFonts.orbitron(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'Sikka Coins',
                              style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),

                            const SizedBox(height: 12),
                            // Divider line
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(height: 1, color: const Color(0xFFF1F5F9)),
                            ),
                            const SizedBox(height: 12),

                            Text('You will receive', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10)),
                            const SizedBox(height: 4),

                             // Base + Extra Bonus Row
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Column(
                                   children: [
                                     Text('Base Amount', style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF64748B))),
                                     Text('₹${opt['baseRupees']}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                     Text('(${opt['coins']} Coins)', style: GoogleFonts.outfit(fontSize: 8, color: const Color(0xFF94A3B8))),
                                   ],
                                 ),
                                 if (opt['bonusRupees'] != null && (opt['bonusRupees'] as int) > 0) ...[
                                   const SizedBox(width: 8),
                                   Container(
                                     padding: const EdgeInsets.all(4),
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       border: Border.all(color: cardColor),
                                     ),
                                     child: Icon(Icons.add, size: 10, color: cardColor),
                                    ),
                                   const SizedBox(width: 8),
                                   Column(
                                     children: [
                                       Text('Extra Bonus', style: GoogleFonts.outfit(fontSize: 9, color: cardColor, fontWeight: FontWeight.bold)),
                                       Text('₹${opt['bonusRupees']}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: cardColor)),
                                       const SizedBox(height: 10),
                                     ],
                                   ),
                                 ],
                               ],
                             ),
                            const SizedBox(height: 10),

                            // Solid Button Container
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedOptionIndex = idx;
                                });
                                _submit();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: buttonColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text('Total You Get', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                    Text('₹${opt['totalRupees']}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                            if (opt['tagline'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(opt['tagline'].toString(), style: GoogleFonts.outfit(color: buttonColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (opt['lightBg'] as Color),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You can claim this offer only once',
                                style: GoogleFonts.outfit(color: buttonColor, fontSize: 8, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. "How it works" Lightbulb Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF7C3AED), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How it works', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF5B21B6))),
                        const SizedBox(height: 2),
                        Text(
                          'Withdraw more than ${widget.minWithdrawalLimit.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} coins and get extra bonus as shown above. These offers are valid for your first withdrawal only.',
                          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6D28D9), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 6. Custom Input Field Box
            Text('Or Enter Custom Coins (Min ${widget.minWithdrawalLimit.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} Coins)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _manualCoinsController,
                enabled: !_isProcessing && widget.withdrawalNotice.isEmpty && widget.options.isNotEmpty,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter Sikka Coins (e.g. 15000)',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF08A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFCA8A04), size: 16),
                  ),
                  suffixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF8B5CF6), size: 20),
                ),
                onChanged: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _selectedOptionIndex = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 18),

            // 7. Saved UPI Details Profile Card
            Text('UPI & Name Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showEditUpiDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Enter Full Name'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            _upiController.text.isNotEmpty ? _upiController.text : 'Tap to enter UPI ID (e.g. 9876543210@paytm)',
                            style: GoogleFonts.outfit(fontSize: 11, color: _upiController.text.isNotEmpty ? const Color(0xFF64748B) : const Color(0xFF8B5CF6)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: Color(0xFF8B5CF6), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            PremiumButton(
              text: widget.withdrawalNotice.isNotEmpty
                  ? 'WITHDRAWAL PAUSED'
                  : widget.options.isEmpty
                      ? 'NO PACKAGES AVAILABLE'
                      : _isProcessing
                          ? 'Processing'
                          : 'PROCEED WITHDRAWAL',
              isLoading: _isProcessing,
              onTap: (widget.withdrawalNotice.isNotEmpty || widget.options.isEmpty || _isProcessing)
                  ? null
                  : _submit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
