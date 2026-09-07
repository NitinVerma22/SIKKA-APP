import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/src/tapjoy_constants.dart';
import './models/models.dart';

class TapjoyMethodCallHandler {

  // Triggers corresponding listener functions.
  static Future<dynamic> handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {

        // Tapjoy connect Events — guard against null listeners to prevent crash
        case 'TapjoyOnConnectSuccess':
          _onConnectSuccessListener?.call();
          return;

        case 'TapjoyOnConnectFailure':
          _onConnectFailureListener?.call(call.arguments["code"], call.arguments["message"]);
          return;

        case 'TapjoyOnConnectWarning':
          _onConnectWarningListener?.call(call.arguments["code"], call.arguments["message"]);
          return;

        // Tapjoy setUserID Events
        case 'TapjoyOnSetUserIDSuccess':
          _onSetUserIDSuccessListener?.call();
          return;

        case 'TapjoyOnSetUserIDFailure':
          _onSetUserIDFailureListener?.call(call.arguments);
          return;

        // Tapjoy getCurrencyBalance Events
        case 'TapjoyOnGetCurrencyBalanceSuccess':
          _onGetCurrencyBalanceSuccessListener?.call(call.arguments["currencyName"], call.arguments["balance"]);
          return;

        case 'TapjoyOnGetCurrencyBalanceFailure':
          _onGetCurrencyBalanceFailureListener?.call(call.arguments);
          return;

        // Tapjoy spendCurrency Events
        case 'TapjoyOnSpendCurrencySuccess':
          _onSpendCurrencySuccessListener?.call(call.arguments["currencyName"], call.arguments["balance"]);
          return;

        case 'TapjoyOnSpendCurrencyFailure':
          _onSpendCurrencyFailureListener?.call(call.arguments);
          return;

        // Tapjoy awardCurrency Events
        case 'TapjoyOnAwardCurrencySuccess':
          _onAwardCurrencySuccessListener?.call(call.arguments["currencyName"], call.arguments["balance"]);
          return;

        case 'TapjoyOnAwardCurrencyFailure':
          _onAwardCurrencyFailureListener?.call(call.arguments);
          return;

        // TJPlacement events
        case 'onRequestSuccess':
          return onRequestSuccess(call.arguments);

        case 'onRequestFailure':
          return onRequestFailure(call.arguments);

        case 'onContentReady':
          return onContentReady(call.arguments);

        case 'onContentShow':
          return onContentShow(call.arguments);

        case 'onContentDismiss':
          return onContentDismiss(call.arguments);

        case TapjoyCallback.onSetCurrencyBalanceSuccess:
          return setCurrencyBalanceSuccess(call.arguments);

        case TapjoyCallback.onSetCurrencyBalanceFailure:
          return setCurrencyBalanceFailure(call.arguments);

        case TapjoyCallback.onSetRequiredAmountSuccess:
          return setRequiredAmountSuccess(call.arguments);

        case TapjoyCallback.onSetRequiredAmountFailure:
          return setRequiredAmountFailure(call.arguments);

        default:
          // Return null instead of throwing — prevents notImplemented on native side
          return null;
      }
    } catch (e) {
      // Catch all exceptions so the handler never crashes and stays alive
      return null;
    }
  }


  // TapjoyOnConnectSuccessListener listener
  static TapjoyOnConnectSuccessListener? _onConnectSuccessListener;
  static void setOnConnectSuccessListener(TapjoyOnConnectSuccessListener? listener) {
    _onConnectSuccessListener = listener;
  }

  // TapjoyOnConnectFailureListener listener
  static TapjoyOnConnectFailureListener? _onConnectFailureListener;
  static void setOnConnectFailureListener(TapjoyOnConnectFailureListener? listener) {
    _onConnectFailureListener = listener;
  }

  // TapjoyOnConnectWarningListener listener
  static TapjoyOnConnectWarningListener? _onConnectWarningListener;
  static void setOnConnectWarningListener(TapjoyOnConnectWarningListener? listener) {
    _onConnectWarningListener = listener;
  }

  // TapjoyOnSetUserIDSuccessListener listener
  static TapjoyOnSetUserIDSuccessListener? _onSetUserIDSuccessListener;
  static void setOnSetUserIDSuccess(TapjoyOnSetUserIDSuccessListener? listener) {
    _onSetUserIDSuccessListener = listener;
  }

  // TapjoyOnSetUserIDFailureListener listener
  static TapjoyOnSetUserIDFailureListener? _onSetUserIDFailureListener;
  static void setOnSetUserIDFailure(TapjoyOnSetUserIDFailureListener? listener) {
    _onSetUserIDFailureListener = listener;
  }

  // TapjoyOnGetCurrencyBalanceSuccessListener listener
  static TapjoyOnGetCurrencyBalanceSuccessListener? _onGetCurrencyBalanceSuccessListener;
  static void setOnGetCurrencyBalanceSuccess(TapjoyOnGetCurrencyBalanceSuccessListener? listener) {
    _onGetCurrencyBalanceSuccessListener = listener;
  }

  // TapjoyOnGetCurrencyBalanceFailureListener listener
  static TapjoyOnGetCurrencyBalanceFailureListener? _onGetCurrencyBalanceFailureListener;
  static void setOnGetCurrencyBalanceFailure(TapjoyOnGetCurrencyBalanceFailureListener? listener) {
    _onGetCurrencyBalanceFailureListener = listener;
  }

  // TapjoyOnSpendCurrencySuccessListener listener
  static TapjoyOnSpendCurrencySuccessListener? _onSpendCurrencySuccessListener;
  static void setOnSpendCurrencySuccess(TapjoyOnSpendCurrencySuccessListener? listener) {
    _onSpendCurrencySuccessListener = listener;
  }

  // TapjoyOnSpendCurrencyFailureListener listener
  static TapjoyOnSpendCurrencyFailureListener? _onSpendCurrencyFailureListener;
  static void setOnSpendCurrencyFailure(TapjoyOnSpendCurrencyFailureListener? listener) {
    _onSpendCurrencyFailureListener = listener;
  }

  // TapjoyOnAwardCurrencySuccessListener listener
  static TapjoyOnAwardCurrencySuccessListener? _onAwardCurrencySuccessListener;
  static void setOnAwardCurrencySuccess(TapjoyOnAwardCurrencySuccessListener? listener) {
    _onAwardCurrencySuccessListener = listener;
  }

  // TapjoyOnAwardCurrencyFailureListener listener
  static TapjoyOnAwardCurrencyFailureListener? _onAwardCurrencyFailureListener;
  static void setOnAwardCurrencyFailure(TapjoyOnAwardCurrencyFailureListener? listener) {
    _onAwardCurrencyFailureListener = listener;
  }

  // TJPlacement onRequestSuccess
  static void onRequestSuccess(arguments) {
    try {
      var placement = TJPlacement.findPlacement(arguments);
      placement?.onRequestSuccess?.call(placement);
    } catch (e) {}
  }

  // TJPlacement onRequestFailure
  static void onRequestFailure(arguments) {
    try {
      var error = arguments["error"];
      var placementName = arguments["placementName"];
      var placement = TJPlacement.findPlacement(placementName);
      placement?.onRequestFailure?.call(placement, error);
    } catch (e) {}
  }

  // TJPlacement onContentReady — calls showContent directly to open the offerwall
  static void onContentReady(arguments) {
    try {
      var placement = TJPlacement.findPlacement(arguments);
      if (placement != null) {
        // Call stored callback first
        placement.onContentReady?.call(placement);
        // Also force showContent directly to ensure the screen opens
        placement.showContent();
      }
    } catch (e) {}
  }

  // TJPlacement onContentShow
  static void onContentShow(arguments) {
    try {
      var placement = TJPlacement.findPlacement(arguments);
      placement?.onContentShow?.call(placement);
    } catch (e) {}
  }

  // TJPlacement onContentDismiss
  static void onContentDismiss(arguments) {
    try {
      var placement = TJPlacement.findPlacement(arguments);
      placement?.onContentDismiss?.call(placement);
    } catch (e) {}
  }

  // TJPlacement setCurrencyBalance success
  static void setCurrencyBalanceSuccess(arguments) {
    try {
      // arguments is the placementName string directly
      var placementName = arguments is String ? arguments : arguments["placementName"];
      var placement = TJPlacement.findPlacement(placementName);
      placement?.onSetCurrencyBalanceSuccess?.call(placement);
    } catch (e) {}
  }

  // TJPlacement setCurrencyBalance failure
  static void setCurrencyBalanceFailure(arguments) {
    try {
      var placementName = arguments["placementName"];
      var placement = TJPlacement.findPlacement(placementName);
      var error = arguments["error"];
      placement?.onSetCurrencyBalanceFailure?.call(placement, error);
    } catch (e) {}
  }

  // TJPlacement setRequiredAmount success
  static void setRequiredAmountSuccess(arguments) {
    try {
      var placement = TJPlacement.findPlacement(arguments);
      placement?.onSetRequiredAmountSuccess?.call(placement);
    } catch (e) {}
  }

  // TJPlacement setRequiredAmount failure
  static void setRequiredAmountFailure(arguments) {
    try {
      var placementName = arguments["placementName"];
      var placement = TJPlacement.findPlacement(placementName);
      var error = arguments["error"];
      placement?.onSetRequiredAmountFailure?.call(placement, error);
    } catch (e) {}
  }
}
