import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_join_dialog.dart';
import '../widgets/tournament_guide_bottom_sheet.dart';

class TournamentsHubScreen extends ConsumerStatefulWidget {
  const TournamentsHubScreen({super.key});

  @override
  ConsumerState<TournamentsHubScreen> createState() => _TournamentsHubScreenState();
}

class _TournamentsHubScreenState extends ConsumerState<TournamentsHubScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _bannerAnimController;
  bool _showFloatingBanner = false;
  Timer? _bannerDelayTimer;
  Timer? _bannerAutoDismissTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(tournamentHubTabProvider.notifier).state = _tabController.index;
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // After 2.5 seconds, show the cute floating book popup
    _bannerDelayTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _showFloatingBanner = true;
      });
      _bannerAnimController.forward();

      // Stays visible for ~3.5 seconds then smoothly docks into top book icon
      _bannerAutoDismissTimer = Timer(const Duration(milliseconds: 3500), () {
        if (!mounted) return;
        _bannerAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showFloatingBanner = false;
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _bannerDelayTimer?.cancel();
    _bannerAutoDismissTimer?.cancel();
    _tabController.dispose();
    _pulseController.dispose();
    _bannerAnimController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final tab = _tabController.index;
    if (tab == 0) {
      ref.invalidate(liveTournamentsProvider);
    } else if (tab == 1) {
      ref.invalidate(upcomingTournamentsProvider);
    } else if (tab == 2) {
      ref.invalidate(myTournamentsProvider);
    } else if (tab == 3) {
      ref.invalidate(completedTournamentsProvider);
    } else {
      ref.invalidate(userHistoryTournamentsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tournaments Arena',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('🏆', style: TextStyle(fontSize: 16)),
              ],
            ),
            Text(
              'Compete in games & win coin pools!',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          _buildBookIconAction(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF6E5DE7),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF6E5DE7),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '🔴 Live Now'),
                Tab(text: '⏰ Upcoming'),
                Tab(text: '👤 My Tournaments'),
                Tab(text: '🏆 Completed'),
                Tab(text: '📜 History'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildLiveTab(),
              _buildUpcomingTab(),
              _buildMyTournamentsTab(),
              _buildCompletedTab(),
              _buildHistoryTab(),
            ],
          ),

          // Animated Floating Tooltip Banner (appears after 2.5s, docks into top book icon)
          if (_showFloatingBanner)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _buildFloatingBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookIconAction() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => TournamentGuideBottomSheet.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      'Guide',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5B21B6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBanner() {
    return AnimatedBuilder(
      animation: _bannerAnimController,
      builder: (context, child) {
        final curve = CurvedAnimation(
          parent: _bannerAnimController,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return Transform.translate(
          offset: Offset(0, (1 - curve.value) * -25),
          child: Opacity(
            opacity: curve.value.clamp(0.0, 1.0),
            child: Transform.scale(
              alignment: Alignment.topRight,
              scale: 0.85 + (0.15 * curve.value),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showFloatingBanner = false;
          });
          TournamentGuideBottomSheet.show(context);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // 📖 Bouncing Book icon with glow
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Text('📖', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              // Text & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kya aap janna chahte hain aapki kamai kaise hogi?',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Yahan Padhein',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFDE047),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Color(0xFFFDE047),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Close button
              GestureDetector(
                onTap: () {
                  _bannerAnimController.reverse().then((_) {
                    if (mounted) {
                      setState(() {
                        _showFloatingBanner = false;
                      });
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTab() {
    final liveAsync = ref.watch(liveTournamentsProvider);
    return RefreshIndicator(
      color: const Color(0xFF6E5DE7),
      onRefresh: _refreshData,
      child: liveAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return _buildEmptyState(
              icon: Icons.sports_esports_rounded,
              title: 'No Live Tournaments Right Now',
              subtitle: 'Check the Upcoming tab for scheduled flash cups & daily tournaments!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return TournamentCard(
                tournament: t,
                onTap: () => context.push('/tournaments/${t.id}'),
                onJoinTap: () => TournamentJoinDialog.show(
                  context: context,
                  ref: ref,
                  tournament: t,
                  onJoinSuccess: () {
                    ref.read(joinedTournamentIdsProvider.notifier).markJoined(t.id);
                    ref.invalidate(liveTournamentsProvider);
                    ref.invalidate(myTournamentsProvider);
                    context.push('/tournaments/${t.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingAsync = ref.watch(upcomingTournamentsProvider);
    return RefreshIndicator(
      color: const Color(0xFF6E5DE7),
      onRefresh: _refreshData,
      child: upcomingAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return _buildEmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No Upcoming Tournaments',
              subtitle: 'New flash tournaments are generated regularly every day!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return TournamentCard(
                tournament: t,
                onTap: () => context.push('/tournaments/${t.id}'),
                onJoinTap: () => TournamentJoinDialog.show(
                  context: context,
                  ref: ref,
                  tournament: t,
                  onJoinSuccess: () {
                    ref.read(joinedTournamentIdsProvider.notifier).markJoined(t.id);
                    ref.invalidate(upcomingTournamentsProvider);
                    ref.invalidate(myTournamentsProvider);
                    context.push('/tournaments/${t.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildMyTournamentsTab() {
    final myAsync = ref.watch(myTournamentsProvider);
    return RefreshIndicator(
      color: const Color(0xFF6E5DE7),
      onRefresh: _refreshData,
      child: myAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return _buildEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'You Haven\'t Joined Any Tournaments',
              subtitle: 'Join a Live or Upcoming tournament to compete on the leaderboard!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return TournamentCard(
                tournament: t,
                onTap: () => context.push('/tournaments/${t.id}'),
                onJoinTap: () => context.push('/tournaments/${t.id}'),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildCompletedTab() {
    final completedAsync = ref.watch(completedTournamentsProvider);
    return RefreshIndicator(
      color: const Color(0xFF6E5DE7),
      onRefresh: _refreshData,
      child: completedAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return _buildEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No Completed Tournaments',
              subtitle: 'Finished tournaments and winners will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return TournamentCard(
                tournament: t,
                onTap: () => context.push('/tournaments/${t.id}/leaderboard'),
                onJoinTap: () => context.push('/tournaments/${t.id}/leaderboard'),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(userHistoryTournamentsProvider);
    return RefreshIndicator(
      color: const Color(0xFF6E5DE7),
      onRefresh: _refreshData,
      child: historyAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history_rounded,
              title: 'No Participation History',
              subtitle: 'Your entered tournaments (live or completed) will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return TournamentCard(
                tournament: t,
                onTap: () {
                  if (t.isCompleted) {
                    context.push('/tournaments/${t.id}/leaderboard');
                  } else {
                    context.push('/tournaments/${t.id}');
                  }
                },
                onJoinTap: () {
                  if (t.isCompleted) {
                    context.push('/tournaments/${t.id}/leaderboard');
                  } else {
                    context.push('/tournaments/${t.id}');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF6E5DE7), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Tournaments',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E5DE7)),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
