import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/services/socket_provider.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';

class PlaygroundMatchmakingScreen extends ConsumerStatefulWidget {
  final String gender;
  const PlaygroundMatchmakingScreen({super.key, required this.gender});

  @override
  ConsumerState<PlaygroundMatchmakingScreen> createState() => _PlaygroundMatchmakingScreenState();
}

class _PlaygroundMatchmakingScreenState extends ConsumerState<PlaygroundMatchmakingScreen> with SingleTickerProviderStateMixin {
  final PlaygroundService _service = PlaygroundService();
  late AnimationController _radarController;
  Timer? _heartbeatTimer;

  bool _isSearching = false;
  String _selectedFilter = 'random'; // 'random' | 'male' | 'female'

  dynamic _cachedSocket;
  String? _cachedUserId;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Setup Socket listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cachedSocket = ref.read(globalSocketProvider);
      _cachedUserId = ref.read(userProvider).userData?['id'];
      if (_cachedSocket != null) {
        _cachedSocket.on('match_found', _onMatchFound);
        _cachedSocket.on('matchmaking_error', _onMatchmakingError);
      }
    });
  }

  void _onMatchFound(dynamic data) {
    if (!mounted) return;
    _stopSearching();
    // Parse data and navigate
    context.pushReplacement('/playground/studio', extra: data);
  }

  void _onMatchmakingError(dynamic data) {
    if (!mounted) return;
    _stopSearching();
    GameNotifications.showCoinUpdate(context, data['message'] ?? 'Matchmaking failed');
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _radarController.dispose();
    
    // Clean up socket listeners
    if (_cachedSocket != null) {
      _cachedSocket.off('match_found', _onMatchFound);
      _cachedSocket.off('matchmaking_error', _onMatchmakingError);
      if (_isSearching && _cachedUserId != null) {
        _cachedSocket.emit('matchmaking_search_cancel', {'userId': _cachedUserId});
      }
    }
    
    super.dispose();
  }

  void _startMatchmaking() {
    final socket = ref.read(globalSocketProvider);
    final userId = ref.read(userProvider).userData?['id'];
    
    if (socket == null || userId == null) {
      GameNotifications.showCoinUpdate(context, 'Connection error. Please try again.');
      return;
    }

    setState(() {
      _isSearching = true;
    });
    _radarController.repeat();

    socket.emit('matchmaking_search_start', {
      'userId': userId,
      'gender': widget.gender,
      'preference': _selectedFilter,
    });

    // Start 15-second heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isSearching) {
        socket.emit('matchmaking_heartbeat', {'userId': userId});
      } else {
        timer.cancel();
      }
    });
  }

  void _stopSearching() {
    _heartbeatTimer?.cancel();
    _radarController.stop();
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
      
      final socket = ref.read(globalSocketProvider);
      final userId = ref.read(userProvider).userData?['id'];
      if (socket != null && userId != null) {
        socket.emit('matchmaking_search_cancel', {'userId': userId});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () {
            _stopSearching();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'MATCHMAKING',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle top gradient
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  _isSearching ? 'SEARCHING FOR PARTNER' : 'SELECT CONNECTION PREFERENCE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSearching
                      ? 'Please wait while we find a match for you...'
                      : 'Choose your matchmaking pool filters.\nPremium filters cost 50 coins.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),

                // Radar animation or filter configuration
                Center(
                  child: _isSearching ? _buildRadarAnimation() : _buildFilterSelector(),
                ),

                const Spacer(),

                if (!_isSearching)
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _startMatchmaking,
                      child: Text(
                        'START FINDING MATCH',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _stopSearching,
                      child: Text(
                        'CANCEL SEARCH',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Column(
      children: [
        _buildFilterItem('Random Connection', 'FREE', 'random', Icons.shuffle_rounded),
        const SizedBox(height: 16),
        _buildFilterItem('Male Partners Only', '50 COINS', 'male', Icons.male_rounded),
        const SizedBox(height: 16),
        _buildFilterItem('Female Partners Only', '50 COINS', 'female', Icons.female_rounded),
      ],
    );
  }

  Widget _buildFilterItem(String title, String subtitle, String filterVal, IconData icon) {
    final isSelected = _selectedFilter == filterVal;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterVal;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8A2BE2) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6F5EFA).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8A2BE2) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: isSelected ? const Color(0xFF8A2BE2) : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF8A2BE2), size: 24)
            else
              const Icon(Icons.radio_button_off, color: Color(0xFFE5E7EB), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave 1
              Container(
                width: 240 * _radarController.value,
                height: 240 * _radarController.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8A2BE2).withValues(alpha: 1.0 - _radarController.value),
                    width: 3,
                  ),
                  color: const Color(0xFF8A2BE2).withValues(alpha: (1.0 - _radarController.value) * 0.1),
                ),
              ),
              // Wave 2
              Container(
                width: 240 * ((_radarController.value + 0.5) % 1.0),
                height: 240 * ((_radarController.value + 0.5) % 1.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6F5EFA).withValues(alpha: 1.0 - ((_radarController.value + 0.5) % 1.0)),
                    width: 3,
                  ),
                  color: const Color(0xFF6F5EFA).withValues(alpha: (1.0 - ((_radarController.value + 0.5) % 1.0)) * 0.1),
                ),
              ),
              // Radar Anchor center
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF6F5EFA)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A2BE2).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}
