import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\screens\win_600_coins_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = "import 'package:sikkaplay/features/profile/controllers/user_controller.dart';"
if import_statement not in content:
    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_statement}")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added import to win_600_coins_screen.dart")
else:
    print("Import already exists")
