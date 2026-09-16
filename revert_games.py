import re

def fix_game(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove incrementGullak
    content = content.replace("    // Increment Gullak progress for completing a level\n    ref.read(win600Provider.notifier).incrementGullak();\n", "")
    content = content.replace("    ref.read(win600Provider.notifier).incrementGullak();\n", "")
    
    # Remove win600Provider import
    content = content.replace("import 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';\n", "")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed {file_path}")

fix_game(r'e:\development\SikkaPlay\lib\features\games\arrow_escape\screens\arrow_escape_game_screen.dart')
fix_game(r'e:\development\SikkaPlay\lib\features\games\bubble_shooter\screens\bubble_shooter_game_screen.dart')
fix_game(r'e:\development\SikkaPlay\lib\features\games\water_sort\screens\water_sort_game_screen.dart')
