import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("TextSpan(text: '90 Coins'", "TextSpan(text: '90\\nCoins'")
content = content.replace("TextSpan(text: '50 - 2000 Coins'", "TextSpan(text: '50 - 2000\\nCoins'")
content = content.replace("TextSpan(text: '30 Coins\\n'", "TextSpan(text: '30\\nCoins\\n'")
content = content.replace("TextSpan(text: '5000 Coins'", "TextSpan(text: '5000\\nCoins'")
content = content.replace("TextSpan(text: '10000 Coins\\n'", "TextSpan(text: '10000\\nCoins\\n'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
