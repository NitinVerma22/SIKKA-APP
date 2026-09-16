import re
file_path = 'lib/shared/layouts/main_layout.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'assets/images/home_cards/earn.png'", "'assets/images/games_hub/coins_stack.png'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
