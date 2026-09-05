import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// SikkaPlay Tapjoy integration for self-managed currency.
///
/// SDK credentials are intentionally supplied at build time with --dart-define
/// and are not stored in the repository.
class TapjoyService {
  TapjoyService._();

  static final TapjoyService instance = TapjoyService._();

  static const String _sdkKey = String.fromEnvironment(
    'TAPJOY_ANDROID_SDK_KEY',
    defaultValue: '',
  );
  static const String placementName = String.fromEnvironment(
    'TAPJOY_PLACEMENT',
    defaultValue: 'earn_coins',
  );
  // Tapjoy SikkaPlay virtual currency ID confirmed by the publisher dashboard.
  static const String currencyId = String.fromEnvironment(
    'TAPJOY_CURRENCY_ID',
    defaultValue: '13f7c34e-9484-43ee-9e82-cd1330940992',
  );

  String? _initializedTapjoyUserId;
  Future<bool>? _initializing;

  bool get isConfigured => Platform.isAndroid && _sdkKey.trim().isNotEmpty;

  /// Converts SikkaPlay's UUID user ID into the numeric, stable Tapjoy user ID
  /// required by self-managed currency. The mapping is reversible on the server.
  String tapjoyUserIdFromUuid(String userId) {
    final normalized = userId.replaceAll('-', '').toLowerCase();
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(normalized)) {
      throw FormatException('Invalid SikkaPlay user ID');
    }
    return BigInt.parse(normalized, radix: 16).toString();
  }

  Future<bool> initialize(String sikkaUserId) {
    final existing = _initializing;
    if (existing != null) return existing;

    final future = _initializeInternal(sikkaUserId);
    _initializing = future;
    future.whenComplete(() => _initializing = null);
    return future;
  }

  Future<bool> _initializeInternal(String sikkaUserId) async {
    if (!Platform.isAndroid) {
      debugPrint('[Tapjoy] Android integration only; skipping on this platform.');
      return false;
    }

    if (!isConfigured) {
      debugPrint('[Tapjoy] SDK key not configured; integration is disabled.');
      return false;
    }

    final tapjoyUserId = tapjoyUserIdFromUuid(sikkaUserId);

    if (_initializedTapjoyUserId == tapjoyUserId && await Tapjoy.isConnected()) {
      return true;
    }

    try {
      await Tapjoy.connect(
        sdkKey: _sdkKey,
        options: <String, dynamic>{
          TapjoyConnectFlags.user_id: tapjoyUserId,
        },
        onConnectSuccess: () {
          debugPrint('[Tapjoy] Connected for user $tapjoyUserId');
        },
        onConnectWarning: (code, warning) {
          debugPrint('[Tapjoy] Connect warning $code: $warning');
        },
        onConnectFailure: (code, error) {
          debugPrint('[Tapjoy] Connect failure $code: $error');
        },
      );

      if (!await Tapjoy.isConnected()) {
        return false;
      }

      _initializedTapjoyUserId = tapjoyUserId;
      return true;
    } catch (e, stack) {
      debugPrint('[Tapjoy] Initialization error: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }

  /// Opens the configured Offerwall placement.
  ///
  /// For self-managed currency, the current SikkaPlay balance is sent to
  /// Tapjoy before content is requested so the Offerwall can display it.
  Future<bool> showOfferwall({required int currentBalance}) async {
    if (!isConfigured) {
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK key is not configured.');
      return false;
    }

    if (!await Tapjoy.isConnected()) {
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK is not connected.');
      return false;
    }

    try {
      final placement = await Tapjoy.getPlacement(
        placementName: placementName,
        onRequestSuccess: (_) {
          debugPrint('[Tapjoy] Placement request sent: $placementName');
        },
        onRequestFailure: (_, error) {
          debugPrint('[Tapjoy] Placement request failed: $error');
        },
        onContentReady: (readyPlacement) async {
          debugPrint('[Tapjoy] Offerwall content ready.');
          await readyPlacement.showContent();
        },
        onContentShow: (_) {
          debugPrint('[Tapjoy] Offerwall content shown.');
        },
        onContentDismiss: (_) {
          debugPrint('[Tapjoy] Offerwall content dismissed.');
        },
      );

      if (currencyId.trim().isNotEmpty) {
        await placement.setCurrencyBalance(
          currencyBalance: currentBalance,
          currencyId: currencyId,
          onSuccess: (_) {
            debugPrint('[Tapjoy] Currency balance synced.');
          },
          onFailure: (_, error) {
            debugPrint('[Tapjoy] Currency balance sync failed: $error');
          },
        );
      } else {
        debugPrint('[Tapjoy] Currency ID not configured; skipping balance sync.');
      }

      await placement.requestContent();
      return true;
    } catch (e, stack) {
      debugPrint('[Tapjoy] Failed to open Offerwall: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }
}
