import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/shared/models/badge_model.dart';

class PlaygroundProfileScreen extends StatefulWidget {
  final String username;

  const PlaygroundProfileScreen({super.key, required this.username});

  @override
  State<PlaygroundProfileScreen> createState() => _PlaygroundProfileScreenState();
}

class _PlaygroundProfileScreenState extends State<PlaygroundProfileScreen> {
  final PlaygroundService _service = PlaygroundService();
  bool _isLoading = true;
  dynamic _user;
  String? _error;

  final List<Map<String, dynamic>> avatarOptions = [
    // Male Avatars (1 to 6)
    {'image': 'assets/images/profile/avatar_1.webp', 'fallbackIcon': Icons.sports_esports_rounded, 'gradient': [const Color(0xFF6F5EFA), const Color(0xFF9B82FF)]},
    {'image': 'assets/images/profile/avatar_2.webp', 'fallbackIcon': Icons.emoji_events_rounded, 'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)]},
    {'image': 'assets/images/profile/avatar_3.webp', 'fallbackIcon': Icons.local_fire_department_rounded, 'gradient': [const Color(0xFFEF4444), const Color(0xFFFF7E40)]},
    {'image': 'assets/images/profile/avatar_4.webp', 'fallbackIcon': Icons.star_rounded, 'gradient': [const Color(0xFF06D6A0), const Color(0xFF00B4D8)]},
    {'image': 'assets/images/profile/avatar_5.webp', 'fallbackIcon': Icons.auto_awesome_rounded, 'gradient': [const Color(0xFF7209B7), const Color(0xFFB5179E)]},
    {'image': 'assets/images/profile/avatar_6.webp', 'fallbackIcon': Icons.favorite_rounded, 'gradient': [const Color(0xFFEC4899), const Color(0xFFFF758C)]},
    // Female Avatars (7 to 12)
    {'image': 'assets/images/profile/avatar_7.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFFFF758C), const Color(0xFFFF7E40)]},
    {'image': 'assets/images/profile/avatar_8.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]},
    {'image': 'assets/images/profile/avatar_9.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF00B4D8), const Color(0xFF6E5DE7)]},
    {'image': 'assets/images/profile/avatar_10.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF06D6A0), const Color(0xFF10B981)]},
    {'image': 'assets/images/profile/avatar_11.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFFFB8500), const Color(0xFFFFB703)]},
    {'image': 'assets/images/profile/avatar_12.webp', 'fallbackIcon': Icons.face_3_rounded, 'gradient': [const Color(0xFF7209B7), const Color(0xFF3F51B5)]},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await _service.getPublicProfile(widget.username);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _user = res['user'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['error'] ?? 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _addFriend() async {
    if (_user == null) return;
    final res = await _service.sendFriendRequest(_user['id']);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Friend request sent!');
      _loadProfileData();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Request failed');
    }
  }

  Future<void> _acceptFriend() async {
    if (_user == null || _user['friendshipId'] == null) return;
    final res = await _service.acceptFriendRequest(_user['friendshipId']);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Friend request accepted!');
      _loadProfileData();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Accept failed');
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'SP';
    final clean = name.trim();
    return clean.substring(0, 1).toUpperCase();
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontSize: 32,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  String _capitalizeName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getGiftEmoji(String giftName) {
    switch (giftName.trim().toLowerCase()) {
      case 'coffee': return '☕';
      case 'heart': return '💖';
      case 'ice cream': return '🍦';
      case 'bouquet': return '💐';
      case 'rose': return '🌹';
      case 'watch': return '⌚';
      case 'chocolate': return '🍫';
      case 'female shoes': return '👠';
      case 'boys shoes': return '👞';
      case 'crown': return '👑';
      case 'female bag': return '👜';
      case 'ring': return '💍';
      case 'dress': return '👗';
      case 'coat pant': return '👔';
      case 'jewelry': return '💎';
      case 'female jackpot': return '🛍️';
      case 'boys kit': return '💼';
      default: return '🎁';
    }
  }


  Widget _buildAvatar(String name, String? avatarUrl, {double size = 52}) {
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

    return Container(
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
                        style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: size * 0.4, fontWeight: FontWeight.bold),
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
                            style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: size * 0.4, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Image.asset(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: size * 0.4, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
            : Center(
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontSize: size * 0.4, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  void _handleExit() {
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/playground/friends');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFBFD),
          elevation: 0,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C096C), size: 14),
                onPressed: _handleExit,
              ),
            ),
          ),
          title: Text(
            'User Profile',
            style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B2CBF)),
                        onPressed: _loadProfileData,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Card
                      _buildTopCard(),
                      const SizedBox(height: 32),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatIcon('Friends', '${_user['friendCount'] ?? 0}', Icons.people_alt_rounded, const Color(0xFF8B5CF6)),
                          _buildStatIcon('Day Streak', '${_user['streak'] ?? 0}', Icons.local_fire_department_rounded, const Color(0xFFFF7E40)),
                          _buildStatIcon('Global Rank', '#${_user['globalRank'] ?? 0}', Icons.emoji_events_rounded, const Color(0xFF06D6A0)),
                          _buildStatIcon('Gifts', '${_user['totalGiftsReceived'] ?? 0}', Icons.card_giftcard_rounded, const Color(0xFF00B4D8)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      if (_user['friendshipState'] == 'FRIENDS')
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: _buildFriendActionButton(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    final matchDetails = {
                                      'channelName': 'private-chat-${_user['id']}',
                                      'agoraToken': 'private-chat-${_user['id']}',
                                      'partnerId': _user['id'],
                                      'partnerName': _user['name'],
                                      'partnerUsername': _user['username'],
                                      'partnerGender': _user['gender'],
                                      'partnerAvatar': _user['avatarUrl']
                                    };
                                    context.push('/playground/studio', extra: matchDetails);
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF8B5CF6)),
                                  label: Text(
                                    'MESSAGE',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF8B5CF6)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: _buildFriendActionButton(),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Gifts Showcase section
                      Text(
                        'Received Gifts',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: const Color(0xFF3C096C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_user['gifts'] != null && (_user['gifts'] as List).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFEFF0F6), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5A3E9C).withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: (_user['gifts'] as List).length,
                            itemBuilder: (context, index) {
                              final item = (_user['gifts'] as List)[index];
                              final gift = item['gift'];
                              final count = item['count'] ?? 1;

                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEFF0F6)),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        gift['imageUrl'] != null && gift['imageUrl'].toString().startsWith('http')
                                            ? CachedNetworkImage(
                                                  imageUrl: gift['imageUrl'],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.contain,
                                                  errorWidget: (context, url, error) => Text(
                                                  _getGiftEmoji(gift['name'] ?? ''),
                                                  style: const TextStyle(fontSize: 32),
                                                ),
                                              )
                                            : Text(
                                                _getGiftEmoji(gift['name'] ?? gift['imageUrl'] ?? ''),
                                                style: const TextStyle(fontSize: 32),
                                              ),
                                        const SizedBox(height: 6),
                                        Text(
                                          gift['name'] ?? 'Gift',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: const Color(0xFF3C096C),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF863BFF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'x$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFD),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5, strokeAlign: BorderSide.strokeAlignOutside),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD8B4E2), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No Gifts Yet!',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: const Color(0xFF7B2CBF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first one to send them a special gift and brighten their day. 🌟',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _unblockUser() async {
    if (_user == null) return;
    GameNotifications.showCoinUpdate(context, 'Unblocking user...');
    final res = await _service.unblockUser(_user['id']);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'User unblocked successfully!');
      _loadProfileData();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Unblock failed');
    }
  }

  Widget _buildFriendActionButton() {
    final state = _user['friendshipState'] ?? 'NONE';

    if (state == 'BLOCKED_BY_ME') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B2CBF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _unblockUser,
        icon: const Icon(Icons.lock_open_rounded, size: 18),
        label: Text(
          'UNBLOCK',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      );
    } else if (state == 'BLOCKED_BY_OTHER') {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.05),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: null,
        icon: const Icon(Icons.block_rounded, size: 18, color: Colors.black38),
        label: Text(
          'BLOCKED',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black38),
        ),
      );
    } else if (state == 'FRIENDS') {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEB),
          side: const BorderSide(color: Color(0xFFFFA3A3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _showUnfriendConfirmDialog,
        icon: const Icon(Icons.person_remove_rounded, size: 18, color: Color(0xFFEF4444)),
        label: Text(
          'UNFRIEND',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFFEF4444)),
        ),
      );
    } else if (state == 'PENDING_SENT') {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.05),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: null,
        icon: const Icon(Icons.hourglass_bottom_rounded, size: 18),
        label: Text(
          'PENDING',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      );
    } else if (state == 'PENDING_RECEIVED') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _acceptFriend,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: Text(
          'ACCEPT',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      );
    } else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _addFriend,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: Text(
          'ADD FRIEND',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      );
    }
  }

  Widget _buildStatIcon(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF1F2937))),
        Text(label, style: GoogleFonts.outfit(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTopCard() {
    final int level = _user['level'] ?? 1;
    final int coins = _user['totalEarned'] ?? 0;
    
    // Calculate dynamic badge rank
    BadgeInfo? activeBadge;
    BadgeInfo? nextBadge;

    for (int i = 0; i < appBadges.length; i++) {
      if (coins >= appBadges[i].targetCoins) {
        activeBadge = appBadges[i];
      } else {
        nextBadge = appBadges[i];
        break;
      }
    }
    
    // If they have all badges, max out the bar
    final double progress = nextBadge != null ? (coins / nextBadge.targetCoins).clamp(0.0, 1.0) : 1.0;
    final String name = _capitalizeName(_user['name']);
    final String username = _user['username'] ?? '';
    final avatarUrl = _user['avatarUrl'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Level Badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? (avatarUrl.toString().startsWith('data:image')
                            ? Image.memory(base64Decode(avatarUrl.toString().split(',').last), fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildInitials(_getInitials(name)))
                              : avatarUrl.toString().startsWith('http')
                                  ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c,u,e) => _buildInitials(_getInitials(name)))
                                : Image.asset(avatarUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildInitials(_getInitials(name))))
                        : _buildInitials(_getInitials(name)),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Center Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF1F2937)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '@$username',
                        style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$coins COINS',
                      style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 14),
                    const SizedBox(width: 4),
                    Text('XP', style: GoogleFonts.outfit(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF3E8FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nextBadge != null ? '${(coins >= 1000 ? '${coins ~/ 1000}k' : '$coins')} / ${nextBadge.targetCoins >= 1000 ? '${nextBadge.targetCoins ~/ 1000}k' : nextBadge.targetCoins}' : 'MAX',
                      style: GoogleFonts.outfit(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Rank Badge
          Column(
            children: [
              if (activeBadge != null)
                Image.asset(activeBadge.imagePath, width: 50, height: 50, errorBuilder: (c,e,s) => Icon(activeBadge!.fallbackIcon, color: activeBadge!.color, size: 40))
              else
                const Icon(Icons.stars_rounded, color: Colors.blueGrey, size: 40),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 8),
          ),
        ],
      ),
    );
  }


  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Block User',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3C096C), fontSize: 16),
          ),
          content: Text(
            'Blocked users won\'t be able to message you or interact with you until you unblock them.',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                GameNotifications.showCoinUpdate(context, 'Blocking user...');
                final res = await _service.blockUser(_user['id']);
                if (mounted) {
                  if (res['success'] == true) {
                    GameNotifications.showCoinUpdate(context, 'User blocked successfully!');
                    Navigator.pop(context); // Go back after blocking
                  } else {
                    GameNotifications.showCoinUpdate(context, res['error'] ?? 'Block failed');
                  }
                }
              },
              child: Text('BLOCK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUnfriendConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Unfriend Partner?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3C096C), fontSize: 16),
          ),
          content: Text(
            'Kya aap sach mein is user ko friends list se hatana chahte hain?',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx); // Close dialog
                GameNotifications.showCoinUpdate(context, 'Unfriending...');
                final res = await _service.unfriendUser(_user['id']);
                if (mounted) {
                  if (res['success'] == true) {
                    GameNotifications.showCoinUpdate(context, 'Unfriended successfully!');
                    _loadProfileData();
                  } else {
                    GameNotifications.showCoinUpdate(context, res['error'] ?? 'Unfriend failed');
                  }
                }
              },
              child: Text('UNFRIEND', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
