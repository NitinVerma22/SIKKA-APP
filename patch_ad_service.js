const fs = require('fs');
const path = 'lib/core/ads/ad_service.dart';
let content = fs.readFileSync(path, 'utf8');

// Add _interstitialShowTime
content = content.replace(
    'InterstitialAd? _interstitialAd;',
    'InterstitialAd? _interstitialAd;\n  DateTime? _interstitialShowTime;'
);

// Set time on show
content = content.replace(
    '        _interstitialAd!.show();',
    '        _interstitialShowTime = DateTime.now();\n        _interstitialAd!.show();'
);

// Check time on dismiss
content = content.replace(
    /onAdDismissedFullScreenContent: \(ad\) {[\s\S]*?loadInterstitialAd\(customAdUnitId: adUnitId\);/,
    \onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              final callback = _currentInterstitialDismissCallback;
              _currentInterstitialDismissCallback = null;
              
              if (_interstitialShowTime != null) {
                final watchDuration = DateTime.now().difference(_interstitialShowTime!);
                if (watchDuration.inSeconds < 3) {
                  debugPrint('AdService: Interstitial Ad skipped too quickly (\s). Callback aborted.');
                  loadInterstitialAd(customAdUnitId: adUnitId);
                  return; // Do not trigger callback
                }
              }
              
              callback?.call();
              loadInterstitialAd(customAdUnitId: adUnitId);\
);

fs.writeFileSync(path, content, 'utf8');
console.log('AdService patched!');
