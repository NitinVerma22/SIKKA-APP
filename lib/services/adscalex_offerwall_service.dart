import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdScaleXOfferwallService {
  static const MethodChannel _channel = MethodChannel('sikkaplay/adscalex');

  static Future<bool> openOfferwall(BuildContext context, String? userId, String? appKey) async {
    if (userId == null || userId.trim().isEmpty) {
      _showError(context, 'Please login to view offers.');
      return false;
    }
    if (appKey == null || appKey.trim().isEmpty) {
      _showError(context, 'Offers are currently unavailable.');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('openOfferwall', {
        'userId': userId.trim(),
        'appKey': appKey.trim(),
      });
      return result['success'] == true;
    } on PlatformException catch (e) {
      debugPrint('AdScaleX Error: ${e.message}');
      _showError(context, 'Could not load offers at this time.');
      return false;
    } catch (e) {
      debugPrint('AdScaleX Error: $e');
      _showError(context, 'An unexpected error occurred.');
      return false;
    }
  }

  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

