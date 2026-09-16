import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the positioning of the image
content = re.sub(
    r'Positioned\(\s*right: -10,\s*bottom: 0,\s*child: SizedBox\(\s*width: 70,\s*height: 70,',
    r'Positioned(\n                right: -15,\n                bottom: 15,\n                child: SizedBox(\n                  width: 95,\n                  height: 95,',
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
