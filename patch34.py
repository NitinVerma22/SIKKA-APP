import re

file_path = r'e:\development\SikkaPlay\pubspec.yaml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = r"- assets/audio/math_rush/\n      - assets/images/"
new_str = "- assets/audio/math_rush/\n    - assets/audio/arrow_escape/\n      - assets/images/"

content = re.sub(old_str, new_str, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("pubspec updated")
