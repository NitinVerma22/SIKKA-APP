import re

file_path = r'e:\development\SikkaPlay\lib\features\games\emoji_memory\screens\emoji_memory_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("int reward = 3;", "int reward = 5;")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated emoji_memory_screen.dart")
