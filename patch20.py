import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = "final userId = ref.read(userProvider).userData?['_id']?.toString() ?? '';"
new_str = "final userId = ref.read(userProvider).userData?['id']?.toString() ?? ref.read(userProvider).userData?['_id']?.toString() ?? '';"

content = content.replace(old_str, new_str)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
