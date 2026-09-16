import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace buttonText with 'Let\\'s Go!'
content = re.sub(r"buttonText: 'Spin Now'", "buttonText: 'Lets Go'", content)
content = re.sub(r"buttonText: 'Enter Code'", "buttonText: 'Lets Go'", content)
content = re.sub(r"buttonText: 'View Offers'", "buttonText: 'Lets Go'", content)
content = re.sub(r"buttonText: 'Start Survey'", "buttonText: 'Lets Go'", content)
content = re.sub(r"buttonText: 'Join Now'", "buttonText: 'Lets Go'", content)
content = re.sub(r"buttonText: 'Find Friends'", "buttonText: 'Lets Go'", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
