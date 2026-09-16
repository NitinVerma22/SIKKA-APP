import re

file_path = r'e:\development\SikkaPlay\pubspec.yaml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace using string replace
old_str = "    - assets/audio/math_rush/\n"
new_str = "    - assets/audio/math_rush/\n    - assets/audio/arrow_escape/\n"

content = content.replace(old_str, new_str)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Pubspec patched correctly.")
