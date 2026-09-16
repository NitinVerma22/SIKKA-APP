import re

file_path = r'e:\development\SikkaPlay\lib\features\home\screens\home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("ref.read(configProvider)", "ref.read(appConfigProvider)")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed configProvider typo")
