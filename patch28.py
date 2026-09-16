import re

file_path = r'e:\development\SikkaPlay\lib\core\user\user_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_methods = """
  Future<Map<String, dynamic>?> incrementGullak() async {
    try {
      final response = await _sendRequest('POST', '/gullak/increment');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error incrementing gullak: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> claimGullakReward() async {
    try {
      final response = await _sendRequest('POST', '/gullak/claim');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error claiming gullak reward: $e');
      return null;
    }
  }
}
"""

content = re.sub(r'}\s*$', new_methods, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
