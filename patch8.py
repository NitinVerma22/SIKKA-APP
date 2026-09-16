import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix maxLines for subtitleWidget
content = re.sub(r'maxLines: 2,\n(.*?)text: const TextSpan', r'maxLines: 4,\n\1text: const TextSpan', content)
content = re.sub(r'maxLines: 3,\n(.*?)text: const TextSpan', r'maxLines: 4,\n\1text: const TextSpan', content)

# Spin Wheel: 90\nCoins (should be visible now with maxLines: 4)

# Daily Code changes
content = content.replace("TextSpan(text: 'Dalo aur jeeto\\n')", "TextSpan(text: 'Win upto\\n')")
content = content.replace("TextSpan(text: '50 - 2000\\nCoins'", "TextSpan(text: '2000\\nCoins'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
