import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sikkaplay/core/user/user_service.dart';

class AdService {
  AdService._privateConstructor();

  static final AdService instance = AdService._privateConstructor();

  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isLoadingRewarded = false;
  bool _isLoadingInterstitial = false;

  // Test Ad Unit IDs provided by Google (Universal Testing IDs)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  /// Initializes the Google Mobile Ads SDK with UMP Consent Flow
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // 1. Request Consent Info
      final params = ConsentRequestParameters();
      
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // 2. Check if form is available
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadConsentForm();
          } else {
            await _initializeAds();
          }
        },
        (FormError error) async {
          debugPrint('AdService Consent Error: ${error.message}');
          await _initializeAds(); // Fallback to initialize
        },
      );
    } catch (e) {
      debugPrint('AdService: Initialization error: $e');
    }
  }

  Future<void> _loadConsentForm() async {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) async {
               // Re-check consent status after showing
               status = await ConsentInformation.instance.getConsentStatus();
               if (status != ConsentStatus.required) {
                 await _initializeAds();
               }
            },
          );
        } else {
           await _initializeAds();
        }
      },
      (FormError formError) async {
        await _initializeAds();
      },
    );
  }

  Future<void> _initializeAds() async {
     if (_isInitialized) return;
     try {
       await MobileAds.instance.initialize();
       _isInitialized = true;
       debugPrint('AdService: Google Mobile Ads SDK initialized successfully.');
        
       Future.delayed(const Duration(seconds: 2), () {
          loadRewardedAd();
          loadInterstitialAd();
       });
     } catch(e) {
       debugPrint('AdService: Initialize Ads failed: $e');
     }
  }

  /// Loads a Rewarded Video Ad in the background
  void loadRewardedAd({String? customAdUnitId}) {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;

    final adUnitId = customAdUnitId ?? testRewardedId;
    debugPrint('AdService: Loading Rewarded Ad for Unit: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('AdService: Rewarded Ad loaded successfully.');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              // Pre-load the next rewarded ad instantly
              loadRewardedAd(customAdUnitId: adUnitId);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(customAdUnitId: adUnitId);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load rewarded ad: $error');
          _isLoadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Plays the loaded Rewarded Video Ad and runs the onEarned callback on completion.
  /// Enforces Server-Side Verification (SSV) options using the userId parameter.
  Future<void> showRewardedAd({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdDismissed,
    required Function(RewardItem reward) onUserEarnedReward,
    String? customAdUnitId,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('AdService: Rewarded ad not ready. Attempting to load...');
      onAdDismissed();
      loadRewardedAd(customAdUnitId: customAdUnitId);
      return;
    }

    // Show Confirmation Dialog before showing the ad!
    final bool? watchAd = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF863BFF), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF863BFF), size: 28),
              const SizedBox(width: 10),
              Text(
                'Watch Video? 🎮',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'Watch video to claim this reward.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF863BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                'WATCH NOW',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (watchAd != true) {
      onAdDismissed();
      return;
    }

    try {
      // Set Server-Side Verification (SSV) options to map user credit requests securely on the backend
      await _rewardedAd!.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: userId,
          customData: 'SikkaPlay_Rewarded_Claim',
        ),
      );

      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutUsed, reward) {
          debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
          UserService().recordAdImpression('rewarded_video', 'admob');
        },
      );
    } catch (e) {
      debugPrint('AdService: Error showing rewarded ad: $e');
      onAdDismissed();
    }
  }

  /// Check if Rewarded Ad is cached and ready to play
  bool isRewardedAdLoaded() {
    return _rewardedAd != null;
  }

  /// Check if Interstitial Ad is cached and ready to play
  bool isInterstitialAdLoaded() {
    return _interstitialAd != null;
  }

  /// Loads an Interstitial Ad in the background
  void loadInterstitialAd({String? customAdUnitId}) {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;

    final adUnitId = customAdUnitId ?? testInterstitialId;
    debugPrint('AdService: Loading Interstitial Ad for Unit: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('AdService: Interstitial Ad loaded successfully.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(customAdUnitId: adUnitId);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(customAdUnitId: adUnitId);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load interstitial ad: $error');
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Plays the loaded Interstitial Ad
  void showInterstitialAd({
    required VoidCallback onAdDismissed,
    String? customAdUnitId,
  }) {
    if (_interstitialAd == null) {
      debugPrint('AdService: Interstitial ad not ready. Load requested.');
      onAdDismissed();
      loadInterstitialAd(customAdUnitId: customAdUnitId);
      return;
    }

    try {
      _interstitialAd!.show();
      UserService().recordAdImpression('interstitial', 'admob');
      onAdDismissed(); // Trigger callback immediately to not block app user transition flow
    } catch (e) {
      debugPrint('AdService: Error showing interstitial ad: $e');
      onAdDismissed();
    }
  }
}
