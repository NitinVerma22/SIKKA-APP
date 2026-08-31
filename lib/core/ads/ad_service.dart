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
  DateTime? _rewardedAdLoadTime;
  DateTime? _rewardedInterstitialAdLoadTime;
  VoidCallback? _currentRewardedDismissCallback;
  VoidCallback? _currentRewardedInterstitialDismissCallback;

  // Test & Production Ad Unit IDs
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String productionBannerId = 'ca-app-pub-8599317656200402/2387421349';

  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String productionRewardedId = 'ca-app-pub-8599317656200402/1786559615';

  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String productionInterstitialId = 'ca-app-pub-8599317656200402/6461186277';

  static const String testRewardedInterstitialId = 'ca-app-pub-3940256099942544/5354046379';
  static const String productionRewardedInterstitialId = 'ca-app-pub-8599317656200402/6078042898';

  /// Returns production Banner Ad Unit ID for Release build, Test ID for Debug build
  static String get bannerAdUnitId => kDebugMode ? testBannerId : productionBannerId;

  /// Returns production Rewarded Ad Unit ID for Release build, Test ID for Debug build
  static String get rewardedAdUnitId => kDebugMode ? testRewardedId : productionRewardedId;

  /// Returns production Interstitial Ad Unit ID for Release build, Test ID for Debug build
  static String get interstitialAdUnitId => kDebugMode ? testInterstitialId : productionInterstitialId;

  /// Returns production Rewarded Interstitial Ad Unit ID for Release build, Test ID for Debug build
  static String get rewardedInterstitialAdUnitId => kDebugMode ? testRewardedInterstitialId : productionRewardedInterstitialId;

  /// Returns whether an Interstitial Ad should be shown for a given level number
  /// - Level 1-10: Every 3 levels (Level 3, 6, 9)
  /// - Level 11-50: Every 2 levels (Alternate)
  /// - Level 51-170: Every single level!
  /// - Level 170+: Interstitial Ads REMOVED (Replaced by mandatory Rewarded Video Ads)
  bool shouldShowLevelCompleteAd(int levelNumber) {
    if (levelNumber > 170) {
      return false; // Interstitial ads REMOVED after level 170!
    }
    if (levelNumber <= 10) {
      return levelNumber % 3 == 0;
    } else if (levelNumber <= 50) {
      return levelNumber % 2 == 0;
    } else {
      return true; // Every single level clear between 51 and 170!
    }
  }

  /// Checks if a level completion is a Milestone Level Lock (Level 60, 80, 100, 120, 140, 150)
  bool isMilestoneLockLevel(int levelNumber) {
    return const {60, 80, 100, 120, 140, 150}.contains(levelNumber);
  }

  /// Checks if level is past 170 where Interstitial Ads are disabled and Rewarded Ads are mandatory after every level
  bool isPost170Level(int levelNumber) {
    return levelNumber > 170;
  }

  /// Unified method to handle Level Complete Transition for any game
  /// Checks Milestone Lock (60, 80, 100, 120, 140, 150), Post-170 Rewarded Ad (>170),
  /// or Interstitial Ad frequency rule before navigating to next level!
  Future<void> handleNextLevelTransition({
    required BuildContext context,
    required int currentLevel,
    required String gameName,
    required VoidCallback onProceedToNextLevel,
  }) async {
    if (isMilestoneLockLevel(currentLevel)) {
      await showMilestoneLockDialog(
        context: context,
        levelCleared: currentLevel,
        userId: '${gameName}_user',
        onUnlocked: onProceedToNextLevel,
      );
    } else if (isPost170Level(currentLevel)) {
      await showPost170RewardedDialog(
        context: context,
        levelCleared: currentLevel,
        userId: '${gameName}_user',
        onEarned: onProceedToNextLevel,
      );
    } else if (shouldShowLevelCompleteAd(currentLevel)) {
      if (!isInterstitialAdLoaded()) {
        loadInterstitialAd();
      }
      showInterstitialAd(onAdDismissed: onProceedToNextLevel);
    } else {
      // Frequency rule says NO AD for this level (e.g. Level 1, 2, or Post 170)
      onProceedToNextLevel();
    }
  }

  /// Displays Milestone Lock Dialog for Level 60, 80, 100, 120, 140, 150
  Future<void> showMilestoneLockDialog({
    required BuildContext context,
    required int levelCleared,
    required String userId,
    required VoidCallback onUnlocked,
  }) async {
    final bool? watchAd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF863BFF), width: 2),
          ),
          title: Column(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 8),
              Text(
                'Milestone Reached! 🎉',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'You have successfully cleared $levelCleared levels!\nWatch a short video ad to unlock next levels & keep playing.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF863BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                'WATCH VIDEO TO UNLOCK 🔓',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );

    if (watchAd == true) {
      showRewardedAd(
        context: context,
        userId: userId,
        onAdDismissed: onUnlocked,
        onUserEarnedReward: (_) => onUnlocked(),
      );
    } else {
      onUnlocked();
    }
  }

  /// Displays Post-170 Rewarded Video Dialog for Levels > 170
  Future<void> showPost170RewardedDialog({
    required BuildContext context,
    required int levelCleared,
    required String userId,
    required VoidCallback onEarned,
  }) async {
    final bool? watchAd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: Column(
            children: [
              const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 8),
              Text(
                'Claim Level $levelCleared Coins! 🪙',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'We are giving many coins! Without your support it\'s impossible to distribute this amount, so please watch this video to claim your coins.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13.5),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                'WATCH VIDEO TO CLAIM COINS 🎥',
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        );
      },
    );

    if (watchAd == true) {
      showRewardedAd(
        context: context,
        userId: userId,
        onAdDismissed: onEarned,
        onUserEarnedReward: (_) => onEarned(),
      );
    } else {
      onEarned();
    }
  }

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
    if (_isLoadingRewarded) return;
    
    if (_rewardedAd != null) {
      if (_rewardedAdLoadTime != null && DateTime.now().difference(_rewardedAdLoadTime!) > const Duration(hours: 4)) {
        debugPrint('AdService: Stale Rewarded Ad detected. Discarding.');
        _rewardedAd!.dispose();
        _rewardedAd = null;
      } else {
        return;
      }
    }

    _isLoadingRewarded = true;
    final adUnitId = customAdUnitId ?? rewardedAdUnitId;
    debugPrint('AdService: Loading Rewarded Ad for Unit: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          _rewardedAdLoadTime = DateTime.now();
          debugPrint('AdService: Rewarded Ad loaded successfully.');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              final callback = _currentRewardedDismissCallback;
              _currentRewardedDismissCallback = null;
              callback?.call();
              loadRewardedAd(customAdUnitId: adUnitId);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Rewarded ad failed to show: ${error.code} - ${error.message}');
              ad.dispose();
              _rewardedAd = null;
              final callback = _currentRewardedDismissCallback;
              _currentRewardedDismissCallback = null;
              callback?.call();
              loadRewardedAd(customAdUnitId: adUnitId);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load rewarded ad: ${error.code} - ${error.message}');
          _isLoadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Plays the loaded Rewarded Video / Rewarded Interstitial Ad and runs the onEarned callback on completion.
  /// Enforces Server-Side Verification (SSV) options using the userId parameter.
  Future<bool> showRewardedAd({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdDismissed,
    required Function(RewardItem reward) onUserEarnedReward,
    String? customAdUnitId,
  }) async {

    if (_rewardedAd != null && _rewardedAdLoadTime != null && DateTime.now().difference(_rewardedAdLoadTime!) > const Duration(hours: 4)) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
    }

    if (_rewardedAd == null) {
      debugPrint('AdService: Rewarded ad not ready. Returning false.');
      loadRewardedAd(customAdUnitId: customAdUnitId);
      loadRewardedInterstitialAd(customAdUnitId: customAdUnitId);
      return false;
    }

    _currentRewardedDismissCallback = onAdDismissed;

    try {
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
      return true;
    } catch (e) {
      debugPrint('AdService: Error showing rewarded ad: $e');
      final callback = _currentRewardedDismissCallback;
      _currentRewardedDismissCallback = null;
      callback?.call();
      return false;
    }
  }

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoadingRewardedInterstitial = false;

  void loadRewardedInterstitialAd({String? customAdUnitId}) {
    if (_isLoadingRewardedInterstitial) return;
    
    if (_rewardedInterstitialAd != null) {
      if (_rewardedInterstitialAdLoadTime != null && DateTime.now().difference(_rewardedInterstitialAdLoadTime!) > const Duration(hours: 4)) {
        debugPrint('AdService: Stale Rewarded Interstitial Ad detected. Discarding.');
        _rewardedInterstitialAd!.dispose();
        _rewardedInterstitialAd = null;
      } else {
        return;
      }
    }

    _isLoadingRewardedInterstitial = true;
    final adUnitId = customAdUnitId ?? rewardedInterstitialAdUnitId;
    debugPrint('AdService: Loading Rewarded Interstitial Ad for Unit: $adUnitId');

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isLoadingRewardedInterstitial = false;
          _rewardedInterstitialAdLoadTime = DateTime.now();
          debugPrint('AdService: Rewarded Interstitial Ad loaded successfully.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              final callback = _currentRewardedInterstitialDismissCallback;
              _currentRewardedInterstitialDismissCallback = null;
              callback?.call();
              loadRewardedInterstitialAd(customAdUnitId: adUnitId);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Rewarded Interstitial ad failed to show: ${error.code} - ${error.message}');
              ad.dispose();
              _rewardedInterstitialAd = null;
              final callback = _currentRewardedInterstitialDismissCallback;
              _currentRewardedInterstitialDismissCallback = null;
              callback?.call();
              loadRewardedInterstitialAd(customAdUnitId: adUnitId);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load Rewarded Interstitial ad: ${error.code} - ${error.message}');
          _isLoadingRewardedInterstitial = false;
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showRewardedInterstitialAd({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdDismissed,
    required Function(RewardItem reward) onUserEarnedReward,
    String? customAdUnitId,
  }) async {
    if (_rewardedInterstitialAd != null && _rewardedInterstitialAdLoadTime != null && DateTime.now().difference(_rewardedInterstitialAdLoadTime!) > const Duration(hours: 4)) {
        _rewardedInterstitialAd!.dispose();
        _rewardedInterstitialAd = null;
    }

    if (_rewardedInterstitialAd == null) {
      debugPrint('AdService: Rewarded Interstitial ad not ready. Returning false.');
      loadRewardedInterstitialAd(customAdUnitId: customAdUnitId);
      return false;
    }

    _currentRewardedInterstitialDismissCallback = onAdDismissed;

    try {
      await _rewardedInterstitialAd!.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: userId,
          customData: 'SikkaPlay_RewardedInterstitial_Claim',
        ),
      );
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (adWithoutUsed, reward) {
          debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
          UserService().recordAdImpression('rewarded_interstitial', 'admob');
        },
      );
      return true;
    } catch (e) {
      debugPrint('AdService: Error showing rewarded interstitial ad: $e');
      final callback = _currentRewardedInterstitialDismissCallback;
      _currentRewardedInterstitialDismissCallback = null;
      callback?.call();
      return false;
    }
  }

  /// Check if Rewarded Ad is cached and ready to play
  bool isRewardedAdLoaded() {
    return _rewardedAd != null;
  }

  /// Check if Rewarded Interstitial Ad is cached and ready to play
  bool isRewardedInterstitialAdLoaded() {
    return _rewardedInterstitialAd != null;
  }

  /// Check if Interstitial Ad is cached and ready to play
  bool isInterstitialAdLoaded() {
    return _interstitialAd != null;
  }

  /// Loads an Interstitial Ad in the background
  void loadInterstitialAd({String? customAdUnitId}) {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;

    final adUnitId = customAdUnitId ?? interstitialAdUnitId;
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
