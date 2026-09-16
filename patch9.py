import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("TextSpan(text: 'Earn ')", "TextSpan(text: 'Win upto\\n')")
content = content.replace("TextSpan(text: '30\\nCoins\\n', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w900, fontSize: 22))", "TextSpan(text: '50000\\nCoins\\n', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w900, fontSize: 22))")
content = content.replace("TextSpan(text: 'per minute')", "TextSpan(text: 'per day', style: TextStyle(fontSize: 11))")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
