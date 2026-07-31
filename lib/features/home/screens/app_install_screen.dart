import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';

class AppOfferItem {
  final String id;
  final String title;
  final String description;
  final String size;
  final int rewardAmount;
  final IconData icon;
  final Color iconBg;

  AppOfferItem({
    required this.id,
    required this.title,
    required this.description,
    required this.size,
    required this.rewardAmount,
    required this.icon,
    required this.iconBg,
  });
}

class AppInstallScreen extends ConsumerStatefulWidget {
  const AppInstallScreen({super.key});

  @override
  ConsumerState<AppInstallScreen> createState() => _AppInstallScreenState();
}

class _AppInstallScreenState extends ConsumerState<AppInstallScreen> {
  final Set<String> _completedOffers = {};
  String? _installingAppId;

  final List<AppOfferItem> _offers = [
    AppOfferItem(
      id: 'binance',
      title: 'Binance Crypto Exchange',
      description: 'Install and create a verified account to earn coins.',
      size: '85 MB',
      rewardAmount: 350,
      icon: Icons.currency_bitcoin,
      iconBg: Colors.yellow.shade800,
    ),
    AppOfferItem(
      id: 'phonepe',
      title: 'PhonePe: UPI payments',
      description: 'Install and complete your first UPI transaction.',
      size: '42 MB',
      rewardAmount: 180,
      icon: Icons.account_balance,
      iconBg: Colors.purple.shade700,
    ),
    AppOfferItem(
      id: 'telegram',
      title: 'Telegram Messenger',
      description: 'Download Telegram app and join our official chat.',
      size: '30 MB',
      rewardAmount: 60,
      icon: Icons.send_rounded,
      iconBg: Colors.blue.shade600,
    ),
    AppOfferItem(
      id: 'gpay',
      title: 'Google Pay payments',
      description: 'Install and register a new UPI bank account.',
      size: '51 MB',
      rewardAmount: 220,
      icon: Icons.payments,
      iconBg: Colors.teal.shade700,
    ),
    AppOfferItem(
      id: 'whatsapp_biz',
      title: 'WhatsApp Business',
      description: 'Download business messenger and setup profile.',
      size: '38 MB',
      rewardAmount: 80,
      icon: Icons.business_center,
      iconBg: Colors.green.shade600,
    ),
  ];

  void _startDownload(AppOfferItem offer) async {
    if (_completedOffers.contains(offer.id) || _installingAppId != null) return;

    setState(() {
      _installingAppId = offer.id;
    });

    // Simulate download flow
    await _showDownloadProgressDialog(offer);

    if (mounted) {
      setState(() {
        _installingAppId = null;
        _completedOffers.add(offer.id);
      });

      // Claim reward
      ref.read(homeProvider.notifier).claimSurvey('Installed ${offer.title}', offer.rewardAmount);
      await ref.read(userProvider.notifier).claimReward(offer.rewardAmount, 'app_install', 'Installed & verified ${offer.title}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer verified! Earned ${offer.rewardAmount} coins.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showDownloadProgressDialog(AppOfferItem offer) async {
    double progress = 0.0;
    String statusText = 'Starting download...';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (progress < 1.0) {
                setStateDialog(() {
                  progress += 0.1;
                  if (progress >= 1.0) {
                    statusText = 'Verifying installation...';
                    Future.delayed(const Duration(seconds: 1), () {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                  } else if (progress > 0.7) {
                    statusText = 'Installing...';
                  } else {
                    statusText = 'Downloading... ${(progress * 100).toInt()}%';
                  }
                });
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.title,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openInstalledApp(AppOfferItem offer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Opening ${offer.title}... 🚀'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Install Apps & Earn',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final isCompleted = _completedOffers.contains(offer.id);
          final isDownloading = _installingAppId == offer.id;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderLight, width: 1),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // App Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: offer.iconBg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(offer.icon, color: offer.iconBg, size: 32),
                  ),
                  const SizedBox(width: 16),
                  // App details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offer.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Text(
                              offer.size,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.description,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Claim Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW USER ONLY',
                            style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Install Button
                  GestureDetector(
                    onTap: isDownloading
                        ? null
                        : isCompleted
                            ? () => _openInstalledApp(offer)
                            : () => _startDownload(offer),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isDownloading ? null : AppColors.primaryGradient,
                        color: isDownloading ? Colors.grey.shade200 : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDownloading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.24),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                      ),
                      child: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : isCompleted
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Go',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+${offer.rewardAmount}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 12),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
