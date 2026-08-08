import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/playground/screens/playground_blocked_users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:ui';

class PlaygroundFriendsScreen extends ConsumerStatefulWidget {
  const PlaygroundFriendsScreen({super.key});

  @override
  ConsumerState<PlaygroundFriendsScreen> createState() => _PlaygroundFriendsScreenState();
}

class _PlaygroundFriendsScreenState extends ConsumerState<PlaygroundFriendsScreen> {
  final PlaygroundService _service = PlaygroundService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _pendingRequests = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, String> _chatClearTimes = {};

  // Tabs state: 0 = All Friends, 1 = Online, 2 = Requests
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFriendsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsData() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _service.getFriendsList();
    if (!mounted) return;

    if (res['success'] == true) {
      final List<dynamic> loadedFriends = res['friends'] ?? [];
      final Map<String, String> clearTimes = {};
      final prefs = await SharedPreferences.getInstance();
      for (var f in loadedFriends) {
        final friendId = f['id']?.toString() ?? '';
        if (friendId.isNotEmpty) {
          final clearTime = prefs.getString('chat_clear_time_$friendId');
          if (clearTime != null) {
            clearTimes[friendId] = clearTime;
          }
        }
      }

      setState(() {
        _friends = loadedFriends;
        _chatClearTimes = clearTimes;
        _pendingRequests = res['pendingRequests'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      GameNotifications.showCoinUpdate(context, 'Failed to load friends');
    }
  }

  void _searchFriends(String val) {
    if (val.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      final query = val.trim().toLowerCase();
      _searchResults = _friends.where((f) {
        final name = (f['name'] ?? '').toString().toLowerCase();
        final username = (f['username'] ?? '').toString().toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
    });
  }

  Future<void> _sendRequest(String targetId) async {
    final res = await _service.sendFriendRequest(targetId);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Friend request sent!');
      _searchController.clear();
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      _loadFriendsData();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Request failed');
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    final res = await _service.acceptFriendRequest(friendshipId);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Request accepted!');
      _loadFriendsData();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Approval failed');
    }
  }

  // --- UI Builders ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAFBFD),
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Color(0xFF3C096C)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaygroundBlockedUsersScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C096C), size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Friends Portal ',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3C096C),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text('🚀', style: TextStyle(fontSize: 18)),
            ],
          ),
          Text(
            '• Chat, Play & Win Together! •',
            style: GoogleFonts.outfit(
              color: Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGrowCircleBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3E8FF).withOpacity(0.8),
            const Color(0xFFFAFBFD),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          // Graphic placeholder
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D5FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.group_add_rounded, color: Color(0xFF7B2CBF), size: 32),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2CBF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No chats found', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF3C096C))),
                const SizedBox(height: 4),
                Text('Add friends to chat, play\nand earn exciting rewards!', style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              GameNotifications.showCoinUpdate(context, 'Invite friends feature coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2CBF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            child: Row(
              children: [
                Text('Invite Friends', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 4),
                const Icon(Icons.person_add_alt_1_rounded, size: 14, color: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.black38, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: const Color(0xFF3C096C)),
                      decoration: InputDecoration(
                        hintText: 'Search by name or username...',
                        hintStyle: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: _searchFriends,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black38, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchFriends('');
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final int onlineCount = _friends.where((f) => f['isOnline'] == true).length;
    final int requestCount = _pendingRequests.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildTabItem(0, 'All', Icons.people_alt_rounded, null, false)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabItem(1, 'Online', Icons.notifications_active_rounded, null, true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabItem(2, 'Requests', Icons.person_add_alt_1_rounded, requestCount > 0 ? requestCount : null, false)),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon, int? badgeCount, bool showOnlineDot) {
    final bool isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B2CBF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF7B2CBF) : Colors.black.withOpacity(0.05)),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 14),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B4B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
            if (showOnlineDot) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return const SizedBox.shrink();
  }

  Widget _buildDynamicList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
    }

    if (_isSearching) {
      if (_searchResults.isEmpty) {
        return _buildEmptyState('No matching users found.');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) => _buildFriendCard(_searchResults[index]),
      );
    }

    if (_selectedTab == 2) {
      if (_pendingRequests.isEmpty) return _buildEmptyState('No pending requests.');
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) => _buildRequestCard(_pendingRequests[index]),
      );
    }

    List<dynamic> displayList = List.from(_friends);
    if (_selectedTab == 1) {
      displayList = displayList.where((f) => f['isOnline'] == true).toList();
      if (displayList.isEmpty) return _buildEmptyState('No friends online right now.');
    }

    // Sort by lastMessageTime descending
    displayList.sort((a, b) {
      final tA = a['lastMessageTime'] != null ? DateTime.tryParse(a['lastMessageTime']) : null;
      final tB = b['lastMessageTime'] != null ? DateTime.tryParse(b['lastMessageTime']) : null;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    });

    if (displayList.isEmpty) return _buildEmptyState('No friends added yet. Use the search box to find users!');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayList.length,
      itemBuilder: (context, index) => _buildFriendCard(displayList[index]),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final String displayName = _capitalizeName(req['name']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildAvatar(displayName, req['avatarUrl'], false),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent you a request',
                  style: GoogleFonts.outfit(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2CBF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => _acceptRequest(req['friendshipId']),
            child: Text(
              'Accept',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user, {required bool isSearch}) {
    final String displayName = _capitalizeName(user['name']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                barrierColor: Colors.black.withValues(alpha: 0.5),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    body: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Blur effect
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(color: Colors.transparent),
                          ),
                          // Center Image
                          Center(
                            child: GestureDetector(
                              onTap: () {}, // Prevent closing when tapping the image itself
                              child: Hero(
                                tag: 'avatar_${user['id']}',
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  height: MediaQuery.of(context).size.width * 0.7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: _buildAvatar(displayName, user['avatarUrl'], false, size: MediaQuery.of(context).size.width * 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Hero(
              tag: 'avatar_${user['id']}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7B2CBF).withValues(alpha: 0.2), width: 2),
                ),
                child: _buildAvatar(displayName, user['avatarUrl'], false),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.w900, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (user['gender']?.toString().toLowerCase() == 'female')
                      const Icon(Icons.female_rounded, color: Colors.pinkAccent, size: 16)
                    else if (user['gender']?.toString().toLowerCase() == 'male')
                      const Icon(Icons.male_rounded, color: Colors.blueAccent, size: 16),
                  ],
                ),
                if (user['username'] != null && user['username'].toString().isNotEmpty)
                  Text(
                    '@${user['username']}',
                    style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF).withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isSearch)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _sendRequest(user['id']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ADD',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(dynamic friend) {
    final String friendId = friend['id']?.toString() ?? '';
    final String? clearTimeStr = _chatClearTimes[friendId];
    
    bool isCleared = false;
    if (clearTimeStr != null && friend['lastMessageTime'] != null) {
      final clearTime = DateTime.tryParse(clearTimeStr);
      final lastMsgTime = DateTime.tryParse(friend['lastMessageTime']);
      if (clearTime != null && lastMsgTime != null) {
        if (lastMsgTime.isBefore(clearTime)) {
          isCleared = true;
        }
      }
    }

    final bool isOnline = friend['isOnline'] == true;
    final int unread = isCleared ? 0 : (friend['unreadCount'] ?? 0);
    
    // Parse time
    String timeStr = '';
    if (!isCleared && friend['lastMessageTime'] != null) {
      final lastMsgTimeUtc = DateTime.tryParse(friend['lastMessageTime']);
      if (lastMsgTimeUtc != null) {
        final lastMsgTime = lastMsgTimeUtc.toLocal();
        final int h = lastMsgTime.hour % 12 == 0 ? 12 : lastMsgTime.hour % 12;
        final String ampm = lastMsgTime.hour >= 12 ? 'PM' : 'AM';
        timeStr = '${h}:${lastMsgTime.minute.toString().padLeft(2, '0')} $ampm';
      }
    }

    final String lastMessageText = isCleared 
        ? 'Tap to start chatting...' 
        : (friend['lastMessageText'] ?? 'Tap to start chatting...');

    final String displayName = _capitalizeName(friend['name']);

    return GestureDetector(
      onTap: () async {
        GameNotifications.showCoinUpdate(context, 'Connecting to $displayName...');
        final mockMatchResult = {
          'channelName': 'friend-chat-${friend['id']}',
          'agoraToken': 'friend-chat-${friend['id']}',
          'partnerId': friend['id'],
          'partnerName': displayName,
          'partnerGender': friend['gender'] ?? 'male',
          'partnerUsername': friend['username'],
          'partnerAvatar': friend['avatarUrl'],
        };
        await GoRouter.of(context).push('/playground/studio', extra: mockMatchResult);
        // Refresh chats after coming back
        _loadFriendsData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(displayName, friend['avatarUrl'], isOnline),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      if (isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Online',
                            style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessageText,
                    style: GoogleFonts.outfit(
                      color: unread > 0 ? const Color(0xFF1F2937) : Colors.black38,
                      fontSize: 12,
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B2CBF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (timeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3E8FF)),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF7B2CBF), size: 16),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl, bool isOnline, {double size = 52}) {
    final initials = _getInitials(name);
    
    final List<Color> pastelColors = [
      const Color(0xFFE9D5FF),
      const Color(0xFFBAE6FD),
      const Color(0xFFFECDD3),
      const Color(0xFFD1FAE5),
      const Color(0xFFFEF08A),
      const Color(0xFFFED7AA),
    ];
    
    final colorIndex = (name.length * 3) % pastelColors.length;
    final bgColor = pastelColors[colorIndex];

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? (avatarUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(avatarUrl.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : avatarUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : Image.asset(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ))
                : Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF06D6A0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final clean = name.trim();
    return clean.substring(0, 1).toUpperCase();
  }

  String _capitalizeName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }


  @override
  Widget build(BuildContext context) {
    // Determine the list size for the header
    int currentCount = 0;
    if (_isSearching) {
      currentCount = _searchResults.length;
    } else if (_selectedTab == 0) {
      currentCount = _friends.length;
    } else if (_selectedTab == 1) {
      currentCount = _friends.where((f) => f['isOnline'] == true).length;
    } else if (_selectedTab == 2) {
      currentCount = _pendingRequests.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_friends.isEmpty) _buildGrowCircleBanner(),
          _buildSearchBar(),
          _buildTabs(),
          _buildListHeader(currentCount),
          Expanded(
            child: _buildDynamicList(),
          ),
        ],
      ),
    );
  }
}
