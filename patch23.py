import re
file_path = 'lib/features/home/screens/daily_code_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'assets/images/daily_code.webp'", "'assets/images/promo_banner_5.webp'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
