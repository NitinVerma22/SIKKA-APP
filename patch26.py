import re

file_path = r'e:\development\SikkaPlay\lib\features\games\shared\utils\game_claim_dialog.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace any occurrence of triggerSync followed by optional incrementGullak with both
pattern = r"ref\.read\(syncCoordinatorProvider\)\.triggerSync\(\[SyncEvent\.balanceChanged\]\);\s*(?:ref\.read\(win600Provider\.notifier\)\.incrementGullak\(\);\s*)?"

replacement = """ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
            ref.read(win600Provider.notifier).incrementGullak();
"""

content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
