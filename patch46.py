import re

file_path = r'e:\development\SikkaPlay\lib\shared\layouts\main_layout.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = """  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my_network')) return 1;
    if (location.startsWith('/games')) return 2;
    if (location.startsWith('/playground/friends')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }"""

new_logic = """  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/playground/friends')) return 3;
    if (location.startsWith('/playground')) return 1;
    if (location.startsWith('/games')) return 2;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched main_layout.dart selected index logic")
else:
    print("Could not find the target codeblock.")
