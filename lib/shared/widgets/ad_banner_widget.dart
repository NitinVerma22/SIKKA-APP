import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/core/user/user_service.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  final String placementName;

  const AdBannerWidget({
    super.key,
    required this.placementName,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // We defer checking of adsEnabled until build, but we can pre-load the ad instance
    _bannerAd = BannerAd(
      adUnitId: AdService.testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdImpression: (ad) {
          UserService().recordAdImpression('banner_${widget.placementName}', 'admob');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdBannerWidget (${widget.placementName}): Failed to load ad: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Read dynamic ad-toggle switches from the backend configuration provider
    final configState = ref.watch(appConfigProvider);
    final bool adsEnabled = configState.config?['adsEnabled'] ?? true;
    final bool bannersEnabled = configState.config?['bannersEnabled'] ?? true;

    // Check specific screen restrictions if passed in placement
    bool screenEnabled = true;
    if (widget.placementName == 'surveys' && configState.config?['surveysAdRequired'] == false) {
      screenEnabled = false;
    }
    if (widget.placementName == 'daily_code' && configState.config?['dailyCodeAdRequired'] == false) {
      screenEnabled = false;
    }

    // If ads are disabled globally or for banners, do not display anything
    if (!adsEnabled || !bannersEnabled || !screenEnabled) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      // Return a clean empty space with the visual divider to reserve layout space and prevent shifts
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: AppColors.borderLight, thickness: 1),
          SizedBox(height: 50), // Reserving empty space for standard banner height
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visual divider separator between game content and the bottom ad to comply with AdMob policy
        const Divider(height: 1, color: AppColors.borderLight, thickness: 1),
        Container(
          color: Colors.white,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          alignment: Alignment.center,
          child: AdWidget(ad: _bannerAd!),
        ),
      ],
    );
  }
}
