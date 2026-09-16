import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace padding
content = content.replace("padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),", "padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
