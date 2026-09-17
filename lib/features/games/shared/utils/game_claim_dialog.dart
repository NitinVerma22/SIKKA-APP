import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';
import 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';

class GameClaimDialog {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required String? sessionId,
    required String gameName,
    required int coinsEarned,
    required VoidCallback onClaimCompleted,
    required VoidCallback onContinue,
    required VoidCallback onExit,
    VoidCallback? onCancel,
  }) {
    final selectedLanguage = ref.read(languageProvider);
    final configState = ref.read(appConfigProvider);
    final String sequenceStr = configState.config?['gullakAdSequence'] ??
        'rewarded_interstitial,rewarded,interstitial';
    final List<String> sequence =
        sequenceStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    if (sequence.isEmpty) sequence.add('rewarded');
    final int claimsToday =
        ref.read(userProvider).userData?['gullakClaimsToday'] ?? 0;
    final String adType = sequence[claimsToday % sequence.length];

    final onCompleteClaim = () async {
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                context.tr('game_session_not_found_err', selectedLanguage))));
        if (onCancel != null) onCancel();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1500));
      final result = await ref
          .read(userServiceProvider)
          .endGameSession(sessionId, coinsEarned: 50);
      if (result != null && result['success'] == true) {
        final int coinsWon = result['coinsEarned'] ?? 0;
        ref
            .read(syncCoordinatorProvider)
            .triggerSync([SyncEvent.balanceChanged]);
        await ref.read(win600Provider.notifier).incrementGullak();
        onClaimCompleted();
        if (context.mounted)
          _showPostClaimDialog(
              context, coinsWon, onContinue, onExit, selectedLanguage);
      } else {
        if (context.mounted) {
          String err = selectedLanguage == 'Hindi'
              ? 'पुरस्कार क्लेम करने में विफल। सत्र बहुत छोटा है?'
              : 'Failed to claim reward. Session too short?';
          if (result != null && result['error'] != null) err = result['error'];
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err)));
        }
        if (onCancel != null) onCancel();
      }
    };

    final showDirectClaimLoaderAndClaim = () async {
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                context.tr('game_session_not_found_err', selectedLanguage))));
        if (onCancel != null) onCancel();
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Center(
          child: Card(
            color: const Color(0xFF1E1E2E),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(context.tr('closing_session_wait', selectedLanguage),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      );
      try {
        await Future.delayed(const Duration(milliseconds: 1500));
        final result = await ref
            .read(userServiceProvider)
            .endGameSession(sessionId, coinsEarned: 25);
        if (context.mounted) Navigator.of(context).pop();
        if (result != null && result['success'] == true) {
          final int coinsWon = result['coinsEarned'] ?? 0;
          ref
              .read(syncCoordinatorProvider)
              .triggerSync([SyncEvent.balanceChanged]);
          await ref.read(win600Provider.notifier).incrementGullak();
          onClaimCompleted();
          if (context.mounted)
            _showPostClaimDialog(
                context, coinsWon, onContinue, onExit, selectedLanguage);
        } else {
          if (context.mounted) {
            String err = selectedLanguage == 'Hindi'
                ? 'पुरस्कार क्लेम करने में विफल। सत्र बहुत छोटा है?'
                : 'Failed to claim reward. Session too short?';
            if (result != null && result['error'] != null)
              err = result['error'];
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(err)));
          }
          if (onCancel != null) onCancel();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        if (onCancel != null) onCancel();
      }
    };

    if (adType == 'none') {
      showDirectClaimLoaderAndClaim();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 5)
                ]),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    height: 150,
                    width: 150,
                    child: Image.asset('assets/images/claim_gullak.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFE9D5FF), width: 2)),
                            child: const Icon(Icons.monetization_on_rounded,
                                color: Colors.amber, size: 80)))),
                const SizedBox(height: 12),
                Text(
                    selectedLanguage == 'Hindi'
                        ? 'गुल्लक क्लेम करें!'
                        : 'Claim Your Gullak!',
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF1E1B4B),
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                    selectedLanguage == 'Hindi'
                        ? 'शानदार काम! आपके सिक्का पुरस्कार आपका इंतजार कर रहे हैं।'
                        : 'Nice work! Your Sikka rewards are waiting for you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFF3E8FF), width: 1.5)),
                    child: Column(children: [
                      Text(
                          selectedLanguage == 'Hindi'
                              ? 'अभी क्लेम क्यों करें?'
                              : 'Why claim now?',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF7C3AED),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: _buildBenefitColumn(
                                    icon: Icons.monetization_on,
                                    iconColor: Colors.amber,
                                    iconBgColor: const Color(0xFFFEF3C7),
                                    title: selectedLanguage == 'Hindi'
                                        ? '35 सिक्के कमाएं'
                                        : 'Earn 35 Coins',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'वॉलेट में तुरंत'
                                        : 'Instant wallet reward')),
                            Container(
                                height: 35,
                                width: 1,
                                color: const Color(0xFFE9D5FF)),
                            Expanded(
                                child: _buildBenefitColumn(
                                    icon: Icons.play_circle_fill_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    iconBgColor: const Color(0xFFEEF2FF),
                                    title: selectedLanguage == 'Hindi'
                                        ? 'एक्स्ट्रा बोनस'
                                        : 'Extra Bonus',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'देखें और +15 पाएं'
                                        : 'Watch & get +15')),
                            Container(
                                height: 35,
                                width: 1,
                                color: const Color(0xFFE9D5FF)),
                            Expanded(
                                child: _buildBenefitColumn(
                                    icon: Icons.bolt_rounded,
                                    iconColor: const Color(0xFF10B981),
                                    iconBgColor: const Color(0xFFECFDF5),
                                    title: selectedLanguage == 'Hindi'
                                        ? 'तेजी से बढ़ें'
                                        : 'Grow Faster',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'खेलें और जीतें'
                                        : 'Play & win big')),
                          ]),
                    ])),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    if (sessionId == null) {
                      if (onCancel != null) onCancel();
                      return;
                    }
                    final userId =
                        ref.read(userProvider).userData?['id'] as String? ?? '';
                    if (adType == 'interstitial') {
                      AdService.instance
                          .showInterstitialAd(onAdDismissed: onCompleteClaim);
                    } else {
                      final playAd = () async {
                        bool success = false;
                        if (adType == 'rewarded_interstitial') {
                          success = await AdService.instance
                              .showRewardedInterstitialAd(
                                  context: context,
                                  userId: userId,
                                  onAdDismissed: () {
                                    if (onCancel != null) onCancel();
                                  },
                                  onUserEarnedReward: (reward) {
                                    onCompleteClaim();
                                  });
                        } else {
                          success = await AdService.instance.showRewardedAd(
                              context: context,
                              userId: userId,
                              onAdDismissed: () {
                                if (onCancel != null) onCancel();
                              },
                              onUserEarnedReward: (reward) {
                                onCompleteClaim();
                              });
                        }
                        if (!success && context.mounted && onCancel != null)
                          onCancel();
                      };
                      final bool isLoaded = adType == 'rewarded_interstitial'
                          ? AdService.instance.isRewardedInterstitialAdLoaded()
                          : AdService.instance.isRewardedAdLoaded();
                      if (!isLoaded && userId.isNotEmpty) {
                        AdService.instance.loadRewardedAd();
                        AdService.instance.loadRewardedInterstitialAd();
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (spinnerContext) => _AdSpinnerDialog(
                                selectedLanguage: selectedLanguage,
                                onAdLoaded: () {
                                  Navigator.of(spinnerContext).pop();
                                  playAd();
                                },
                                onTimeout: () {
                                  Navigator.of(spinnerContext).pop();
                                  if (onCancel != null) onCancel();
                                }));
                      } else {
                        playAd();
                      }
                    }
                  },
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(18)),
                      child: Center(
                          child: Text(
                              selectedLanguage == 'Hindi'
                                  ? 'विज्ञापन देखें और क्लेम करें'
                                  : 'Watch Ad & Claim',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)))),
                ),
                const SizedBox(height: 10),
                TextButton(
                    onPressed: showDirectClaimLoaderAndClaim,
                    child: Text(
                        selectedLanguage == 'Hindi'
                            ? 'विज्ञापन के बिना क्लेम करें'
                            : 'Claim without ad',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildBenefitColumn(
          {required IconData icon,
          required Color iconColor,
          required Color iconBgColor,
          required String title,
          required String desc}) =>
      Column(children: [
        Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(height: 6),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
        const SizedBox(height: 2),
        Text(desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)))
      ]);

  static void _showPostClaimDialog(BuildContext context, int coinsWon,
      VoidCallback onContinue, VoidCallback onExit, String selectedLanguage) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text(
                    selectedLanguage == 'Hindi'
                        ? 'पुरस्कार मिल गया! 🎉'
                        : 'Reward Claimed! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800)),
                content: Text(
                    selectedLanguage == 'Hindi'
                        ? '$coinsWon सिक्के आपके वॉलेट में जुड़ गए हैं।'
                        : '$coinsWon coins have been added to your wallet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: const Color(0xFF6B7280))),
                actions: [
                  Row(children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onExit();
                            },
                            child: Text(selectedLanguage == 'Hindi'
                                ? 'बाहर निकलें'
                                : 'Exit'))),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onContinue();
                            },
                            child: Text(selectedLanguage == 'Hindi'
                                ? 'जारी रखें'
                                : 'Continue')))
                  ])
                ]));
  }
}

class _AdSpinnerDialog extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback onAdLoaded;
  final VoidCallback onTimeout;
  const _AdSpinnerDialog(
      {required this.selectedLanguage,
      required this.onAdLoaded,
      required this.onTimeout});
  @override
  State<_AdSpinnerDialog> createState() => _AdSpinnerDialogState();
}

class _AdSpinnerDialogState extends State<_AdSpinnerDialog> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), widget.onTimeout);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted &&
          (AdService.instance.isRewardedAdLoaded() ||
              AdService.instance.isRewardedInterstitialAdLoaded())) {
        _timer?.cancel();
        widget.onAdLoaded();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
