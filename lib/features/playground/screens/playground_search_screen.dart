import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';

class PlaygroundSearchScreen extends StatefulWidget {
  const PlaygroundSearchScreen({super.key});

  @override
  State<PlaygroundSearchScreen> createState() => _PlaygroundSearchScreenState();
}

class _PlaygroundSearchScreenState extends State<PlaygroundSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlaygroundService _service = PlaygroundService();
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  Timer? _debounce;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await _service.searchFriends(query);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _searchResults = res['users'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['error'] ?? 'Search failed';
        _isLoading = false;
      });
    }
  }

  Widget _buildUserItem(dynamic user) {
    final String name = user['name'] ?? 'User';
    final String username = user['username'] ?? 'user';
    final String avatarUrl = user['avatarUrl'] ?? '';
    final String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return InkWell(
      onTap: () {
        context.push('/playground/profile', extra: username);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3E8FF),
                border: Border.all(color: const Color(0xFF8A2BE2), width: 1.5),
              ),
              child: avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: avatarUrl.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(avatarUrl.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitials(initials),
                            )
                          : avatarUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _buildInitials(initials),
                                )
                              : Image.asset(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildInitials(initials),
                                ),
                    )
                  : _buildInitials(initials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '@$username',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF8A2BE2),
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by name or username...',
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
              border: InputBorder.none,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.05),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8A2BE2)),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.outfit(color: Colors.redAccent),
                        ),
                      )
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                                const SizedBox(height: 12),
                                Text(
                                  'No users found',
                                  style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return _buildUserItem(_searchResults[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
