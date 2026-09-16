import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'Connect,\\nchat and get\\nexciting gifts!'", "'Connect,\\nchat and\\nget gifts!'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
