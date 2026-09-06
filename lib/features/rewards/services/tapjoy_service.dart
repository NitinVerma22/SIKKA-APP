import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// SikkaPlay Tapjoy integration for self-managed currency.
class TapjoyService {
  TapjoyService._();

  static final TapjoyService instance = TapjoyService._();

  static const String _sdkKey = String.fromEnvironment(
    'TAPJOY_ANDROID_SDK_KEY',
    defaultValue: 'E_fDTpSEQ-6egs0TMJQJkgECaNhNdJHvrP5Yce3WAmgKVuk0Dslrjo1LbxTg',
  );
  static const String placementName = String.fromEnvironment(
    'TAPJOY_PLACEMENT',
    defaultValue: 'earn_coins',
  );
  static const String currencyId = String.fromEnvironment(
    'TAPJOY_CURRENCY_ID',
    defaultValue: '13f7c34e-9484-43ee-9e82-cd1330940992',
  );

  String? _initializedTapjoyUserId;
  Future<bool>? _initializing;
  bool _sdkConnected = false;
  String? _lastConnectError;
  int? _lastConnectCode;
  String? _lastPlacementError;

  bool get isConfigured => Platform.isAndroid && _sdkKey.trim().isNotEmpty;
  String? get lastConnectError => _lastConnectError;
  int? get lastConnectCode => _lastConnectCode;
  String? get lastPlacementError => _lastPlacementError;

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
      _lastConnectError = 'Android only';
      return false;
    }

    if (!isConfigured) {
      _lastConnectError = 'SDK key is empty';
      return false;
    }

    final tapjoyUserId = tapjoyUserIdFromUuid(sikkaUserId);

    try {
      // Do not make a second native isConnected() call the source of truth after
      // a successful connect callback. The callback is the SDK initialization
      // signal; using isConnected() here can produce a false negative during
      // the short native initialization window.
      if (_initializedTapjoyUserId == tapjoyUserId && _sdkConnected) {
        return true;
      }

      _lastConnectError = null;
      _lastConnectCode = null;
      _lastPlacementError = null;
      _sdkConnected = false;

      await Tapjoy.setDebugEnabled(true);
      await Tapjoy.setLoggingLevel(TJLoggingLevel.debug);

      for (var attempt = 1; attempt <= 3; attempt++) {
        final completer = Completer<bool>();

        debugPrint('[Tapjoy] Connecting attempt $attempt; placement=$placementName; currencyId=$currencyId');
        debugPrint('[Tapjoy] SDK key configured=${_sdkKey.trim().isNotEmpty}, length=${_sdkKey.length}');
        debugPrint('[Tapjoy] Tapjoy user ID=$tapjoyUserId');

        await Tapjoy.connect(
          sdkKey: _sdkKey,
          options: <String, dynamic>{
            TapjoyConnectFlags.user_id: tapjoyUserId,
          },
          onConnectSuccess: () {
            _sdkConnected = true;
            _initializedTapjoyUserId = tapjoyUserId;
            debugPrint('[Tapjoy] CONNECT SUCCESS');
            if (!completer.isCompleted) completer.complete(true);
          },
          onConnectWarning: (code, warning) {
            debugPrint('[Tapjoy] CONNECT WARNING code=$code error=$warning');
          },
          onConnectFailure: (code, error) {
            _sdkConnected = false;
            _lastConnectCode = code;
            _lastConnectError = error ?? 'Unknown Tapjoy connection failure';
            debugPrint('[Tapjoy] CONNECT FAILURE code=$code error=$error');
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        final callbackResult = await completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _sdkConnected = false;
            _lastConnectError = 'Tapjoy connect callback timed out after 15 seconds';
            return false;
          },
        );

        if (callbackResult && _sdkConnected) {
          return true;
        }

        // A native SDK can finish initialization just after the callback future
        // resolves. Treat a positive native state as success, but never turn a
        // successful callback into a failure by requiring an immediate second
        // isConnected() check.
        try {
          if (await Tapjoy.isConnected()) {
            _sdkConnected = true;
            _initializedTapjoyUserId = tapjoyUserId;
            debugPrint('[Tapjoy] SDK reports connected after callback result.');
            return true;
          }
        } catch (e) {
          debugPrint('[Tapjoy] isConnected check failed: $e');
        }

        if (attempt < 3) {
          debugPrint('[Tapjoy] Retrying connection...');
          await Future.delayed(Duration(seconds: attempt));
        }
      }

      debugPrint('[Tapjoy] FINAL CONNECTION FAILURE code=$_lastConnectCode error=$_lastConnectError');
      return false;
    } catch (e, stack) {
      _sdkConnected = false;
      _lastConnectError = e.toString();
      debugPrint('[Tapjoy] Initialization exception: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }

  Future<bool> showOfferwall({required int currentBalance}) async {
    if (!isConfigured) {
      _lastPlacementError = 'SDK key is not configured';
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK key is not configured.');
      return false;
    }

    if (!_sdkConnected) {
      _lastPlacementError = 'Tapjoy SDK is not connected';
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK is not connected. lastError=$_lastConnectError code=$_lastConnectCode');
      return false;
    }

    try {
      _lastPlacementError = null;

      final placement = await Tapjoy.getPlacement(
        placementName: placementName,
        onRequestSuccess: (_) {
          debugPrint('[Tapjoy] PLACEMENT REQUEST SUCCESS: $placementName');
        },
        onRequestFailure: (_, error) {
          _lastPlacementError = error ?? 'Unknown placement request failure';
          debugPrint('[Tapjoy] PLACEMENT REQUEST FAILURE: $error');
        },
        onContentReady: (readyPlacement) async {
          debugPrint('[Tapjoy] OFFERWALL CONTENT READY');
          try {
            await readyPlacement.showContent();
            debugPrint('[Tapjoy] OFFERWALL SHOW REQUESTED');
          } catch (e, stack) {
            _lastPlacementError = 'Failed to show Offerwall: $e';
            debugPrint('[Tapjoy] Failed to show Offerwall: $e');
            debugPrintStack(stackTrace: stack);
          }
        },
        onContentShow: (_) {
          debugPrint('[Tapjoy] OFFERWALL CONTENT SHOWN');
        },
        onContentDismiss: (_) {
          debugPrint('[Tapjoy] OFFERWALL CONTENT DISMISSED');
        },
      );

      if (placement == null) {
        _lastPlacementError = 'Tapjoy returned a null placement';
        debugPrint('[Tapjoy] Placement is null');
        return false;
      }

      await placement.setCurrencyBalance(
        currencyBalance: currentBalance,
        currencyId: currencyId,
        onSuccess: (_) {
          debugPrint('[Tapjoy] CURRENCY BALANCE SYNC SUCCESS');
        },
        onFailure: (_, error) {
          _lastPlacementError = error ?? 'Currency balance sync failed';
          debugPrint('[Tapjoy] CURRENCY BALANCE SYNC FAILURE: $error');
        },
      );

      await placement.requestContent();
      return true;
    } catch (e, stack) {
      _lastPlacementError = e.toString();
      debugPrint('[Tapjoy] Failed to open Offerwall: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }
}
