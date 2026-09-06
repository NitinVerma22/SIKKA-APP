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
  String? _lastConnectError;
  int? _lastConnectCode;

  bool get isConfigured => Platform.isAndroid && _sdkKey.trim().isNotEmpty;
  String? get lastConnectError => _lastConnectError;
  int? get lastConnectCode => _lastConnectCode;

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
      if (_initializedTapjoyUserId == tapjoyUserId && await Tapjoy.isConnected()) {
        return true;
      }

      _lastConnectError = null;
      _lastConnectCode = null;

      await Tapjoy.setDebugEnabled(true);
      await Tapjoy.setLoggingLevel(TJLoggingLevel.debug);

      for (var attempt = 1; attempt <= 2; attempt++) {
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
            debugPrint('[Tapjoy] CONNECT SUCCESS');
            if (!completer.isCompleted) completer.complete(true);
          },
          onConnectWarning: (code, warning) {
            debugPrint('[Tapjoy] CONNECT WARNING code=$code error=$warning');
          },
          onConnectFailure: (code, error) {
            _lastConnectCode = code;
            _lastConnectError = error ?? 'Unknown Tapjoy connection failure';
            debugPrint('[Tapjoy] CONNECT FAILURE code=$code error=$error');
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        final callbackResult = await completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _lastConnectError = 'Tapjoy connect callback timed out after 15 seconds';
            return false;
          },
        );

        if (callbackResult) {
          _initializedTapjoyUserId = tapjoyUserId;
          return true;
        }

        if (await Tapjoy.isConnected()) {
          debugPrint('[Tapjoy] SDK reports connected after callback result.');
          _initializedTapjoyUserId = tapjoyUserId;
          return true;
        }

        if (attempt < 2) {
          debugPrint('[Tapjoy] Retrying connection...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      debugPrint('[Tapjoy] FINAL CONNECTION FAILURE code=$_lastConnectCode error=$_lastConnectError');
      return false;
    } catch (e, stack) {
      _lastConnectError = e.toString();
      debugPrint('[Tapjoy] Initialization exception: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }

  Future<bool> showOfferwall({required int currentBalance}) async {
    if (!isConfigured) {
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK key is not configured.');
      return false;
    }

    if (!await Tapjoy.isConnected()) {
      debugPrint('[Tapjoy] Cannot show Offerwall: SDK is not connected. lastError=$_lastConnectError code=$_lastConnectCode');
      return false;
    }

    try {
      final placement = await Tapjoy.getPlacement(
        placementName: placementName,
        onRequestSuccess: (_) {
          debugPrint('[Tapjoy] PLACEMENT REQUEST SUCCESS: $placementName');
        },
        onRequestFailure: (_, error) {
          debugPrint('[Tapjoy] PLACEMENT REQUEST FAILURE: $error');
        },
        onContentReady: (readyPlacement) async {
          debugPrint('[Tapjoy] OFFERWALL CONTENT READY');
          await readyPlacement.showContent();
        },
        onContentShow: (_) {
          debugPrint('[Tapjoy] OFFERWALL CONTENT SHOWN');
        },
        onContentDismiss: (_) {
          debugPrint('[Tapjoy] OFFERWALL CONTENT DISMISSED');
        },
      );

      if (placement == null) {
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
          debugPrint('[Tapjoy] CURRENCY BALANCE SYNC FAILURE: $error');
        },
      );

      await placement.requestContent();
      return true;
    } catch (e, stack) {
      debugPrint('[Tapjoy] Failed to open Offerwall: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }
}
