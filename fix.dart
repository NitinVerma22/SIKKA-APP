import 'dart:io';

void main() {
  final files = [
    'lib/features/games/water_sort/screens/water_sort_game_screen.dart',
    'lib/features/games/bubble_shooter/screens/bubble_shooter_game_screen.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    content = content.replaceAll(
      "ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);\n        GameNotifications.showCoinUpdate(context, '+\\\ Sikka');",
      "if (_earnedCoins > 0) {\n          ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);\n          GameNotifications.showCoinUpdate(context, '+\\\ Sikka');\n        }"
    );

    content = content.replaceAll(
      "ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);\r\n        GameNotifications.showCoinUpdate(context, '+\\\ Sikka');",
      "if (_earnedCoins > 0) {\n          ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);\n          GameNotifications.showCoinUpdate(context, '+\\\ Sikka');\n        }"
    );

    content = content.replaceAll(
      "Container(\n                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),",
      "if (_earnedCoins > 0) Container(\n                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),"
    );

    content = content.replaceAll(
      "Container(\r\n                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),",
      "if (_earnedCoins > 0) Container(\r\n                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),"
    );
    
    file.writeAsStringSync(content);
  }
}
