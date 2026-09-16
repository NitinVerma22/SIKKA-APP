import re

file_path = r'e:\development\SikkaPlay\lib\features\home\screens\home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_str = "import 'package:sikkaplay/core/navigation/app_navigator.dart';"
new_import = "import 'package:sikkaplay/core/navigation/app_navigator.dart';\nimport 'package:sikkaplay/core/config/config_service.dart';"
content = content.replace(import_str, new_import)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("home_screen.dart updated with config_service import")
