import re

def patch_file(file_path, old_complete, new_complete):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "win_600_provider" not in content:
        # Add import after user_controller
        content = content.replace("import 'package:sikkaplay/features/profile/controllers/user_controller.dart';",
                                  "import 'package:sikkaplay/features/profile/controllers/user_controller.dart';\nimport 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';")
    
    content = content.replace(old_complete, new_complete)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Patched {file_path}")

bubble_path = r'e:\development\SikkaPlay\lib\features\games\bubble_shooter\screens\bubble_shooter_game_screen.dart'
old_bubble = '''  Future<void> _onLevelComplete() async {
    setState(() {
      gameWon = true;
      _isClaiming = true;
    });'''
new_bubble = '''  Future<void> _onLevelComplete() async {
    // Increment Gullak progress for completing a level
    ref.read(win600Provider.notifier).incrementGullak();
    
    setState(() {
      gameWon = true;
      _isClaiming = true;
    });'''
patch_file(bubble_path, old_bubble, new_bubble)

water_path = r'e:\development\SikkaPlay\lib\features\games\water_sort\screens\water_sort_game_screen.dart'
old_water = '''  Future<void> _onLevelComplete() async {
    setState(() {
      _isLevelWon = true;
      _isClaiming = true;
    });'''
new_water = '''  Future<void> _onLevelComplete() async {
    // Increment Gullak progress for completing a level
    ref.read(win600Provider.notifier).incrementGullak();
    
    setState(() {
      _isLevelWon = true;
      _isClaiming = true;
    });'''
patch_file(water_path, old_water, new_water)
