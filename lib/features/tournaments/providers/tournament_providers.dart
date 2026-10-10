import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_models.dart';
import '../services/tournament_service.dart';

/// Global in-memory tournament session tracker for attaching tournamentId
/// to game completion calls when playing inside a tournament arena.
class TournamentSessionTracker {
  static String? activeTournamentId;

  static void setActiveTournament(String? id) {
    activeTournamentId = id;
  }

  static void clear() {
    activeTournamentId = null;
  }
}

final tournamentServiceProvider = Provider<TournamentService>((ref) {
  return TournamentService();
});

/// Tracks the active tournament ID if the user is playing inside a tournament arena.
/// When set, game completions route coins/score to this tournament.
final activeTournamentIdProvider = StateNotifierProvider<ActiveTournamentNotifier, String?>((ref) {
  return ActiveTournamentNotifier();
});

class ActiveTournamentNotifier extends StateNotifier<String?> {
  ActiveTournamentNotifier() : super(TournamentSessionTracker.activeTournamentId);

  void setActive(String? id) {
    state = id;
    TournamentSessionTracker.setActiveTournament(id);
  }

  void clear() {
    state = null;
    TournamentSessionTracker.clear();
  }
}

/// Currently selected Hub screen tab: 0=Live, 1=Upcoming, 2=My Tournaments, 3=History
final tournamentHubTabProvider = StateProvider<int>((ref) => 0);

/// Live tournaments provider
final liveTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournaments(status: TournamentStatus.live);
});

/// Upcoming tournaments provider
final upcomingTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournaments(status: TournamentStatus.upcoming);
});

/// Completed tournaments provider
final completedTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournaments(status: TournamentStatus.completed);
});

/// User joined tournaments provider
final myTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getMyTournaments();
});

/// Tournament details provider
final tournamentDetailProvider = FutureProvider.family.autoDispose<Tournament?, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getTournamentDetails(tournamentId);
});

/// Tournament leaderboard provider
final tournamentLeaderboardProvider = FutureProvider.family.autoDispose<TournamentLeaderboardData?, String>((ref, tournamentId) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getLeaderboard(tournamentId);
});
