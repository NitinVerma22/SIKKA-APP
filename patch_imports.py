import re

def fix_imports(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "win_600_provider" not in content:
        content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';",
                                  "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed imports in {file_path}")

fix_imports(r'e:\development\SikkaPlay\lib\features\games\bubble_shooter\screens\bubble_shooter_game_screen.dart')
fix_imports(r'e:\development\SikkaPlay\lib\features\games\water_sort\screens\water_sort_game_screen.dart')
