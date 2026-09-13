import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdScaleXOfferwallService {
  static const MethodChannel _channel = MethodChannel('sikkaplay/adscalex');
  static const String _appKey = 'psk_NfPTjRGS0a5f6vcljv0ScBZohLYIxOFsdfCRE9kfrtQ';

  static Future<bool> openOfferwall(BuildContext context, String? userId) async {
    if (userId == null || userId.trim().isEmpty) {
      _showError(context, 'Please login to view offers.');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('openOfferwall', {
        'userId': userId.trim(),
        'appKey': _appKey,
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

