import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_join_dialog.dart';

class TournamentsHubScreen extends ConsumerStatefulWidget {
  const TournamentsHubScreen({super.key});

  @override
  ConsumerState<TournamentsHubScreen> createState() => _TournamentsHubScreenState();
}

class _TournamentsHubScreenState extends ConsumerState<TournamentsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(tournamentHubTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🏆', style: TextStyle(fontSize: 18)),
              ],
            ),
            Text(
              'Compete in games & win coin pools!',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTab(),
          _buildUpcomingTab(),
          _buildMyTournamentsTab(),
          _buildCompletedTab(),
          _buildHistoryTab(),
        ],
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
