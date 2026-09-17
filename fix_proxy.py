import re

file_path = r'e:\development\SikkaPlay\backend\src\index.ts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "app.set('trust proxy'" not in content:
    content = content.replace("const app = express();", "const app = express();\napp.set('trust proxy', 1);")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added trust proxy")
else:
    print("Already there")
