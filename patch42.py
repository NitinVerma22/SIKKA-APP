import re

file_path = r'e:\development\SikkaPlay\lib\features\playground\screens\playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports for global providers
if 'main_layout.dart' not in content:
    content = content.replace("import 'package:sikkaplay/core/config/config_service.dart';", "import 'package:sikkaplay/core/config/config_service.dart';\nimport 'package:sikkaplay/shared/layouts/main_layout.dart';")

# Remove local state for friends and pendingRequests
content = content.replace("  List<dynamic> _friends = [];\n  List<dynamic> _pendingRequests = [];", """  List<dynamic> get _friends => ref.watch(globalFriendsListProvider);
  List<dynamic> get _pendingRequests => ref.watch(globalPendingRequestsProvider);""")

# Change initState _isLoading logic
old_init = """  void initState() {
    super.initState();
    _loadFriendsData();
    _loadSuggestions(isRefresh: true);
  }"""
new_init = """  void initState() {
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
content = content.replace(old_init, new_init)

# Update _loadFriendsData to not overwrite local _friends
old_load = """      setState(() {
        _friends = loadedFriends;
        _chatClearTimes = clearTimes;
        _pendingRequests = res['pendingRequests'] ?? [];
        _isSuspended = res['isSuspended'] == true;
        _suspendedUntil = res['suspendedUntil']?.toString();
        _suspendedReason = res['suspendedReason']?.toString();
        _isLoading = false;
      });"""
new_load = """      ref.read(globalFriendsListProvider.notifier).state = loadedFriends;
      ref.read(globalPendingRequestsProvider.notifier).state = res['pendingRequests'] ?? [];
      
      setState(() {
        _chatClearTimes = clearTimes;
        _isSuspended = res['isSuspended'] == true;
        _suspendedUntil = res['suspendedUntil']?.toString();
        _suspendedReason = res['suspendedReason']?.toString();
        _isLoading = false;
      });"""
content = content.replace(old_load, new_load)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated playground_friends_screen.dart")
