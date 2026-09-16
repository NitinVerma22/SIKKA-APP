import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\screens\win_600_coins_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'assets/images/games_hub/gullak.png'", "'assets/images/claim_gullak.webp'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated gullak image in win_600_coins_screen.dart")
