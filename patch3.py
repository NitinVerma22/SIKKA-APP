import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace fontSize: 14 or 15 in the coin spans with fontSize: 18
content = re.sub(
    r"TextSpan\(text: '90 Coins', style: TextStyle\(color: Color\(0xFFE91E63\), fontWeight: FontWeight\.w800, fontSize: \d+\)\)",
    r"TextSpan(text: '90 Coins', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w900, fontSize: 18))",
    content
)

content = re.sub(
    r"TextSpan\(text: '50 - 2000 Coins', style: TextStyle\(color: Color\(0xFF1976D2\), fontWeight: FontWeight\.w800, fontSize: \d+\)\)",
    r"TextSpan(text: '50 - 2000 Coins', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 18))",
    content
)

content = re.sub(
    r"TextSpan\(text: '30 Coins\\n', style: TextStyle\(color: Color\(0xFFF57C00\), fontWeight: FontWeight\.w800, fontSize: \d+\)\)",
    r"TextSpan(text: '30 Coins\\n', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w900, fontSize: 18))",
    content
)

content = re.sub(
    r"TextSpan\(text: '5000 Coins', style: TextStyle\(color: Color\(0xFF7B1FA2\), fontWeight: FontWeight\.w800, fontSize: \d+\)\)",
    r"TextSpan(text: '5000 Coins', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.w900, fontSize: 18))",
    content
)

content = re.sub(
    r"TextSpan\(text: '10000 Coins\\n', style: TextStyle\(color: Color\(0xFF388E3C\), fontWeight: FontWeight\.w800, fontSize: \d+\)\)",
    r"TextSpan(text: '10000 Coins\\n', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w900, fontSize: 18))",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
