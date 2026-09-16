import re

file_path = r'e:\development\SikkaPlay\lib\shared\layouts\main_layout.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = r"final selectedLanguage = ref\.watch\(languageProvider\);"
new_str = """final selectedLanguage = ref.watch(languageProvider);
    
    int profileBadgeCount = ref.watch(notificationProvider).unreadCount;
    int chatBadgeCount = ref.watch(globalPendingRequestsProvider).length;
    for (final friend in ref.watch(globalFriendsListProvider)) {
      chatBadgeCount += (friend['unreadCount'] as int? ?? 0);
    }"""
content = re.sub(old_str, new_str, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Added variables")
