import re

file_path = r'e:\development\SikkaPlay\lib\features\playground\screens\playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("_loadFriendsData();", "_loadFriendsData(silent: true);")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated playground_friends_screen.dart all silent")
