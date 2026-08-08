import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/playground_service.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';

class PlaygroundBlockedUsersScreen extends ConsumerStatefulWidget {
  const PlaygroundBlockedUsersScreen({super.key});

  @override
  ConsumerState<PlaygroundBlockedUsersScreen> createState() => _PlaygroundBlockedUsersScreenState();
}

class _PlaygroundBlockedUsersScreenState extends ConsumerState<PlaygroundBlockedUsersScreen> {
  final PlaygroundService _service = PlaygroundService();
  bool _isLoading = true;
  List<dynamic> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    final res = await _service.getBlockedUsers();
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _blockedUsers = res['blockedUsers'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to load blocked users');
    }
  }

  Future<void> _unblockUser(String targetUserId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unblock User', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF3C096C))),
        content: Text(
          'Once unblocked, this user will be able to message you again if allowed by the app rules.',
          style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Unblock', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    GameNotifications.showCoinUpdate(context, 'Unblocking...');
    final res = await _service.unblockUser(targetUserId);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Unblocked $name successfully!');
      _loadBlockedUsers();
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Unblock failed');
    }
  }

  Future<void> _deleteChat(String targetUserId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Conversation', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF3C096C))),
        content: Text(
          'This will permanently delete your copy of this conversation.',
          style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    GameNotifications.showCoinUpdate(context, 'Deleting chat...');
    final res = await _service.clearChatHistory(targetUserId);
    if (!mounted) return;

    if (res['success'] == true) {
      GameNotifications.showCoinUpdate(context, 'Conversation deleted!');
    } else {
      GameNotifications.showCoinUpdate(context, res['error'] ?? 'Deletion failed');
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAFBFD),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C096C), size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Blocked Users',
        style: GoogleFonts.outfit(
          color: const Color(0xFF3C096C),
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }
  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return '';
    }
  }

  Widget _buildBlockedUserCard(dynamic user) {
    final String name = user['name'] ?? 'Unknown';
    final String username = user['username'] ?? '';
    final String avatarUrl = user['avatarUrl'] ?? '';
    final String targetUserId = user['userId'] ?? '';
    final String blockedAt = _formatDate(user['blockedAt'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF3E8FF),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: GoogleFonts.outfit(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (blockedAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Blocked on $blockedAt',
                        style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _unblockUser(targetUserId, name),
                  child: Text('Unblock', style: GoogleFonts.outfit(color: const Color(0xFF374151), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _deleteChat(targetUserId),
                  child: Text('Delete Chat', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, size: 64, color: Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF3C096C)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When you block someone, they\'ll appear here.',
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) => _buildBlockedUserCard(_blockedUsers[index]),
                ),
    );
  }
}
