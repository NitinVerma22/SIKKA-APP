import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/rewards/services/tapjoy_service.dart';

class AppInstallScreen extends ConsumerStatefulWidget {
  const AppInstallScreen({super.key});

  @override
  ConsumerState<AppInstallScreen> createState() => _AppInstallScreenState();
}

class _AppInstallScreenState extends ConsumerState<AppInstallScreen> {
  bool _openingOfferwall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTapjoy();
    });
  }

  Future<void> _initializeTapjoy() async {
    final userId = ref.read(userProvider).userData?['id']?.toString();
    if (userId == null || userId.isEmpty) return;
    await TapjoyService.instance.initialize(userId);
  }

  Future<void> _openOfferwall() async {
    if (_openingOfferwall) return;

    final userState = ref.read(userProvider);
    final userId = userState.userData?['id']?.toString();
    final balance = (userState.userData?['balance'] as num?)?.toInt() ?? 0;

    if (userId == null || userId.isEmpty) {
      _showMessage('Please wait for your profile to load.');
      return;
    }

    if (!TapjoyService.instance.isConfigured) {
      _showMessage('Offerwall is not configured in this build yet.');
      return;
    }

    setState(() => _openingOfferwall = true);

    try {
      final initialized = await TapjoyService.instance.initialize(userId);
      if (!initialized) {
        _showMessage('Unable to connect to offers. Please try again.');
        return;
      }

      final opened = await TapjoyService.instance.showOfferwall(
        currentBalance: balance,
      );

      if (!opened) {
        _showMessage('Offers are temporarily unavailable. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() => _openingOfferwall = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final balance = (userState.userData?['balance'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Install Apps & Earn',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userProvider.notifier).refresh(silent: true);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Earn More Coins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete app installs, game milestones and other partner offers to earn Sikka Coins.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current balance: $balance coins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openingOfferwall ? null : _openOfferwall,
                      icon: _openingOfferwall
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.local_offer_rounded),
                      label: Text(
                        _openingOfferwall ? 'Opening Offers...' : 'VIEW OFFERS',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _infoTile(
              icon: Icons.install_mobile_rounded,
              title: 'Install & Try',
              description: 'Discover partner apps and complete their required actions.',
            ),
            _infoTile(
              icon: Icons.sports_esports_rounded,
              title: 'Complete Milestones',
              description: 'Some offers reward you for reaching levels or completing tasks.',
            ),
            _infoTile(
              icon: Icons.verified_rounded,
              title: 'Verified Rewards',
              description: 'Rewards are credited after the partner network verifies the completed offer.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Rewards may take some time to appear after an offer is completed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
