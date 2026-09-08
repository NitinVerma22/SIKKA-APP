import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class NativeAdWidget extends StatefulWidget {
  final bool isSmallCard;
  
  const NativeAdWidget({
    super.key,
    this.isSmallCard = true,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final type = widget.isSmallCard ? TemplateType.small : TemplateType.medium;

    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native Ad loaded.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: type,
        mainBackgroundColor: widget.isSmallCard ? const Color(0xFFEEF2FF) : Colors.white,
        cornerRadius: 24.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.primary,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textPrimary,
          backgroundColor: widget.isSmallCard ? const Color(0xFFEEF2FF) : Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          backgroundColor: widget.isSmallCard ? const Color(0xFFEEF2FF) : Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          backgroundColor: widget.isSmallCard ? const Color(0xFFEEF2FF) : Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final height = widget.isSmallCard ? 124.0 : 320.0;

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(
        vertical: AppSizes.md, 
        horizontal: widget.isSmallCard ? 0 : AppSizes.md
      ),
      decoration: BoxDecoration(
        color: widget.isSmallCard ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (widget.isSmallCard)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            ...AppColors.premiumShadow,
        ],
        border: widget.isSmallCard ? null : Border.all(color: AppColors.borderLight, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 320, 
          minHeight: height,
          maxWidth: 400,
          maxHeight: height,
        ),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
