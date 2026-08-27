import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/shared/models/badge_model.dart';

class PlaygroundLobbyScreen extends StatefulWidget {
  const PlaygroundLobbyScreen({super.key});

  @override
  State<PlaygroundLobbyScreen> createState() => _PlaygroundLobbyScreenState();
}

class _PlaygroundLobbyScreenState extends State<PlaygroundLobbyScreen> {
  final PlaygroundService _service = PlaygroundService();
  bool _isLoading = true;

  int _sikkaBalance = 0;
  int _activeMinutes = 0;
  int _activeSecondsToday = 0;
  int _totalEarned = 0;
  int _friendsCount = 0;
  int _streak = 0;
  int _globalRank = 0;
  int _dailyLogin = 0;

  bool _bronzeClaimed = false;
  bool _silverClaimed = false;
  bool _goldClaimed = false;

  String? _username;
  String? _avatarUrl;

  int _selectedAvatarIndex = 0;
  String _initials = 'SP';
  String _gender = 'male';

  final List<Map<String, dynamic>> avatarOptions = [
    {'image': 'assets/images/profile/avatar_1.webp', 'fallbackIcon': Icons.sports_esports_rounded, 'gradient': [const Color(0xFF6F5EFA), const Color(0xFF9B82FF)]},
    {'image': 'assets/images/profile/avatar_2.webp', 'fallbackIcon': Icons.emoji_events_rounded, 'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)]},
    {'image': 'assets/images/profile/avatar_3.webp', 'fallbackIcon': Icons.local_fire_department_rounded, 'gradient': [const Color(0xFFEF4444), const Color(0xFFFF7E40)]},
    {'image': 'assets/images/profile/avatar_4.webp', 'fallbackIcon': Icons.star_rounded, 'gradient': [const Color(0xFF06D6A0), const Color(0xFF00B4D8)]},
    {'image': 'assets/images/profile/avatar_5.webp', 'fallbackIcon': Icons.auto_awesome_rounded, 'gradient': [const Color(0xFF7209B7), const Color(0xFFB5179E)]},
    {'image': 'assets/images/profile/avatar_6.webp', 'fallbackIcon': Icons.favorite_rounded, 'gradient': [const Color(0xFFEC4899), const Color(0xFFFF758C)]},
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
    _loadLobbyData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLobbyData() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _service.getLobbyData();
    final prefs = await SharedPreferences.getInstance();
    
    if (!mounted) return;

    if (res['success'] == true) {
      final progress = res['crateProgress'];
      final name = res['name'] ?? 'SikkaPlay Player';
      
      String initials = 'SP';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ');
        if (parts.length > 1) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          initials = name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
        }
      }

      setState(() {
        _sikkaBalance = res['balance'] ?? 0;
        _activeMinutes = res['playgroundMinutes'] ?? 0;
        _username = res['username'] ?? name;
        _avatarUrl = res['avatarUrl'];
        _initials = initials;
        _gender = res['gender'] ?? 'male';
        _selectedAvatarIndex = prefs.getInt('selected_avatar_index') ?? 0;
        
        _totalEarned = res['totalEarned'] ?? 0;
        _friendsCount = res['friendsCount'] ?? 0;
        _streak = res['streak'] ?? 0;
        _globalRank = res['globalRank'] ?? 0;
        int totalGifts = 0;
        final giftInv = res['giftInventory'];
        if (giftInv != null && giftInv is List) {
          for (var item in giftInv) {
            totalGifts += (item['count'] as int? ?? 1);
          }
        }
        _dailyLogin = totalGifts;

        if (progress != null) {
          _activeSecondsToday = progress['activeSeconds'] ?? 0;
          _bronzeClaimed = progress['bronzeClaimed'] ?? false;
          _silverClaimed = progress['silverClaimed'] ?? false;
          _goldClaimed = progress['goldClaimed'] ?? false;
        }
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _claimCrate(String level) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
        ),
      ),
    );

    final res = await _service.claimCrate(level);
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (res['success'] == true) {
      final int coinsReward = level == 'BRONZE' ? 300 : level == 'SILVER' ? 600 : 1200;
      setState(() {
        if (level == 'BRONZE') _bronzeClaimed = true;
        if (level == 'SILVER') _silverClaimed = true;
        if (level == 'GOLD') _goldClaimed = true;
        _sikkaBalance += coinsReward;
      });
      
      if (mounted) {
        GameNotifications.showCoinUpdate(context, 'Claimed $level Crate! +$coinsReward Sikka');
      }
    } else {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to claim crate', isPenalty: true);
      }
    }
  }

  void _showUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(text: _username ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Username', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixText: '@',
                prefixStyle: const TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold),
                hintText: 'Enter username (3-15 chars)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A2BE2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              if (newUsername.isEmpty) return;
              Navigator.pop(ctx);
              final res = await _service.setUsername(newUsername);
              if (res['success'] == true && mounted) {
                GameNotifications.showCoinUpdate(context, 'Username updated successfully!');
                _loadLobbyData();
              } else if (mounted) {
                GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to update username');
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => context.push('/playground/search'),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6F5EFA).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
              const SizedBox(width: 12),
              Text(
                'Find friends...',
                style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    // Calculate dynamic badge rank
    BadgeInfo? activeBadge;
    BadgeInfo? nextBadge;

    for (int i = 0; i < appBadges.length; i++) {
      if (_totalEarned >= appBadges[i].targetCoins) {
        activeBadge = appBadges[i];
      } else {
        nextBadge = appBadges[i];
        break;
      }
    }
    
    // Default to the first badge if not unlocked yet
    if (activeBadge == null && appBadges.isNotEmpty) {
      nextBadge = appBadges[0];
    }

    final double progress = nextBadge != null
        ? (_totalEarned / nextBadge.targetCoins).clamp(0.0, 1.0)
        : 1.0;

    final userLevel = (_totalEarned / 1000).floor() + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F5EFA).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8A2BE2), width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? (_avatarUrl!.startsWith('data:image')
                            ? Image.memory(base64Decode(_avatarUrl!.split(',').last), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF8A2BE2), child: Center(child: Text(_initials, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))))
                            : _avatarUrl!.startsWith('http')
                                ? CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF8A2BE2), child: Center(child: Text(_initials, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))))
                                : Image.asset(_avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF8A2BE2), child: Center(child: Text(_initials, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))))))
                        : _selectedAvatarIndex == 0
                            ? Container(
                                color: const Color(0xFF8A2BE2),
                                child: Center(
                                  child: Text(
                                    _initials,
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Image.asset(
                                avatarOptions[_selectedAvatarIndex - 1]['image'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF8A2BE2), child: Center(child: Text(_initials, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
                              ),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A2BE2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$userLevel', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${_username ?? 'User'}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                  ],
                ),
                InkWell(
                  onTap: _showUsernameDialog,
                  child: Row(
                    children: [
                      Text('@${_username?.replaceAll(' ', '').toLowerCase() ?? 'user'}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8A2BE2))),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14, color: Color(0xFF8A2BE2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Image.asset('assets/images/icons/coin.webp', width: 20, height: 20, errorBuilder: (_,__,___) => const Icon(Icons.monetization_on, color: Colors.amber, size: 20)),
                    const SizedBox(width: 4),
                    Text('$_sikkaBalance COINS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8A2BE2))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB703)),
                    const SizedBox(width: 4),
                    Text('XP', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nextBadge != null ? '${(_totalEarned >= 1000 ? '${_totalEarned ~/ 1000}k' : '$_totalEarned')} / ${nextBadge.targetCoins >= 1000 ? '${nextBadge.targetCoins ~/ 1000}k' : nextBadge.targetCoins}' : 'MAX', 
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280))
                    ),
                  ],
                )
              ],
            ),
          ),
          // Badge
          if (activeBadge != null)
            Image.asset(activeBadge.imagePath, width: 64, height: 64, errorBuilder: (_,__,___) => Icon(activeBadge!.fallbackIcon, size: 64, color: activeBadge.color)),
          if (activeBadge == null)
            Icon(Icons.military_tech_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(Icons.people_alt_rounded, const Color(0xFF8A2BE2), '$_friendsCount', 'Friends'),
          _buildStatItem(Icons.local_fire_department_rounded, const Color(0xFFFF7E40), '$_streak', 'Day Streak'),
          _buildStatItem(Icons.emoji_events_rounded, const Color(0xFF00B4D8), '#$_globalRank', 'Global Rank'),
          _buildStatItem(Icons.card_giftcard_rounded, const Color(0xFF10B981), '$_dailyLogin', 'Gifts'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildPlaytimeCrates() {
    final int activeMinutes = _activeSecondsToday ~/ 60;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6F5EFA).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('PLAYTIME REWARDS', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF374151))),
                          const SizedBox(width: 4),
                          const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Play games to claim these rewards', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6F5EFA), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF8A2BE2)),
                    const SizedBox(width: 4),
                    Text('Active: ${activeMinutes}m', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8A2BE2))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildCrate(
                    'BRONZE',
                    '60m',
                    activeMinutes,
                    60,
                    _bronzeClaimed,
                    const Color(0xFFFFF1F2),
                    const Color(0xFFE11D48),
                    Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCrate(
                    'SILVER',
                    '120m',
                    activeMinutes,
                    120,
                    _silverClaimed,
                    const Color(0xFFF0F9FF),
                    const Color(0xFF0284C7),
                    Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCrate(
                    'GOLD',
                    '180m',
                    activeMinutes,
                    180,
                    _goldClaimed,
                    const Color(0xFFFEF3C7),
                    const Color(0xFFD97706),
                    Icons.inventory_2_rounded,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCrate(
    String name,
    String time,
    int current,
    int total,
    bool isClaimed,
    Color bgColor,
    Color progressColor,
    IconData icon,
  ) {
    final bool canClaim = current >= total && !isClaimed;
    final double progressValue = (current / total).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        if (isClaimed) {
          GameNotifications.showCoinUpdate(context, 'Already claimed this reward!', isPenalty: true);
        } else if (current < total) {
          final diff = total - current;
          GameNotifications.showCoinUpdate(context, 'Play for $diff more minutes to unlock!', isPenalty: true);
        } else {
          _claimCrate(name);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isClaimed ? Colors.grey[100] : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canClaim 
                ? progressColor 
                : (isClaimed ? Colors.transparent : progressColor.withValues(alpha: 0.1)),
            width: canClaim ? 2.0 : 1.0,
          ),
          boxShadow: canClaim 
              ? [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isClaimed ? Colors.grey[500] : progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              isClaimed ? Icons.check_circle_rounded : icon,
              size: 48,
              color: isClaimed ? const Color(0xFF10B981) : progressColor,
            ),
            const SizedBox(height: 8),
            Text(
              isClaimed ? 'Claimed' : time,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClaimed ? Colors.grey[600] : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isClaimed ? 1.0 : progressValue,
                backgroundColor: isClaimed 
                    ? Colors.grey[300] 
                    : progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isClaimed ? const Color(0xFF10B981) : progressColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isClaimed ? 'Claimed' : '$current / $total',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: isClaimed ? Colors.grey[500] : progressColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF6F5EFA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6F5EFA).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              context.push('/playground/matchmaking', extra: {'gender': _gender});
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'CONNECT WITH STRANGER',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)))
        : Stack(
            children: [
              // Background gradient blob at top
              Positioned(
                top: -100,
                left: -50,
                right: -50,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF3E8FF).withValues(alpha: 0.8),
                        const Color(0xFFFAFBFD),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopAppBar(),
                      _buildProfileCard(),
                      _buildStatsRow(),
                      _buildPlaytimeCrates(),
                      _buildConnectButton(), // Replaces Friends Online & Activity Feed
                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
