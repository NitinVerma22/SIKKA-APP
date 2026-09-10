import 'package:url_launcher/url_launcher.dart';

class CpaleadOfferwallService {
  static const String _baseUrl = 'https://www.cdndn.com/wall/f4a8';

  static Future<bool> openForUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return false;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'subid': id});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
