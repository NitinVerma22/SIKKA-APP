import re

file_path = r'e:\development\SikkaPlay\lib\features\playground\screens\playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_init = """  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(globalFriendsListProvider).isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
      _loadFriendsData();
      _loadSuggestions(isRefresh: true);
    });
  }"""
new_init = """  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPreloaded = ref.read(globalFriendsListProvider).isNotEmpty;
      if (isPreloaded) {
        setState(() {
          _isLoading = false;
        });
      }
      _loadFriendsData(silent: isPreloaded);
      _loadSuggestions(isRefresh: true);
    });
  }"""
content = content.replace(old_init, new_init)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated playground_friends_screen.dart init state")
