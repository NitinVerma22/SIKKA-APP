import re

file_path = r'e:\development\SikkaPlay\lib\core\user\user_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("await _sendRequest('POST', '/gullak/increment')", "await _sendRequest('POST', '/gullak/increment', body: {})")
content = content.replace("await _sendRequest('POST', '/gullak/claim')", "await _sendRequest('POST', '/gullak/claim', body: {})")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed user_service.dart")
