import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdGemOfferwallService {
  static const String _appId = '33508';
  static const String _baseUrl = 'https://api.adgem.com/v1/wall';

  /// Opens the AdGem offerwall for the given user ID.
  /// Validates the user ID according to AdGem requirements.
  static Future<void> openForUser(BuildContext context, String? userId) async {
    if (userId == null || userId.trim().isEmpty) {
      _showError(context, 'Please login to view offers.');
      return;
    }

    final trimmedId = userId.trim().toLowerCase();

    // AdGem requires playerid to be alphanumeric, hyphens, or underscores
    final validIdRegex = RegExp(r'^[a-z0-9_-]+$');
    if (!validIdRegex.hasMatch(trimmedId)) {
      _showError(context, 'Invalid User ID format for offers.');
      return;
    }

    final uri = Uri.parse('$_baseUrl?appid=$_appId&playerid=$trimmedId');

    try {
      if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        _showError(context, 'Could not open offers.');
      }
    } catch (e) {
      debugPrint('Error launching AdGem offerwall: $e');
      _showError(context, 'An error occurred while opening offers.');
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
