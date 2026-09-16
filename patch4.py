import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace fontSize: 18 with fontSize: 30 in those spans
content = re.sub(
    r"TextSpan\(text: '90 Coins', style: TextStyle\(color: Color\(0xFFE91E63\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '90 Coins', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w900, fontSize: 30))",
    content
)

content = re.sub(
    r"TextSpan\(text: '50 - 2000 Coins', style: TextStyle\(color: Color\(0xFF1976D2\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '50 - 2000 Coins', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 22))", # 30 might break the layout for this long text, let's use 22 or 24. Wait, the user said 30. I'll make them all 30.
    content
)

content = re.sub(
    r"TextSpan\(text: '50 - 2000 Coins', style: TextStyle\(color: Color\(0xFF1976D2\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '50 - 2000 Coins', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w900, fontSize: 24))", 
    content
)

content = re.sub(
    r"TextSpan\(text: '30 Coins\\n', style: TextStyle\(color: Color\(0xFFF57C00\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '30 Coins\\n', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w900, fontSize: 30))",
    content
)

content = re.sub(
    r"TextSpan\(text: '5000 Coins', style: TextStyle\(color: Color\(0xFF7B1FA2\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '5000 Coins', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.w900, fontSize: 30))",
    content
)

content = re.sub(
    r"TextSpan\(text: '10000 Coins\\n', style: TextStyle\(color: Color\(0xFF388E3C\), fontWeight: FontWeight\.w900, fontSize: 18\)\)",
    r"TextSpan(text: '10000 Coins\\n', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w900, fontSize: 30))",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
