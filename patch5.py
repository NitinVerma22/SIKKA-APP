import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace fontSize: 30 or 24 with fontSize: 22
content = re.sub(r'fontSize: 30', r'fontSize: 22', content)
content = re.sub(r'fontSize: 24', r'fontSize: 22', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
