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

/// In-memory tracker of tournament IDs that the user has joined during this app session.
/// Provides immediate, instantaneous (0ms) reactive updates to CTA buttons and status banners
/// before asynchronous network refetches complete.
final joinedTournamentIdsProvider = StateNotifierProvider<JoinedTournamentsNotifier, Set<String>>((ref) {
  return JoinedTournamentsNotifier();
});

class JoinedTournamentsNotifier extends StateNotifier<Set<String>> {
  JoinedTournamentsNotifier() : super({});

  void markJoined(String tournamentId) {
    state = {...state, tournamentId};
  }

  bool isJoined(String tournamentId) {
    return state.contains(tournamentId);
  }

  void reset() {
    state = {};
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
  return service.getCompletedTournaments();
});

/// User joined tournaments provider (active live)
final myTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getMyTournaments();
});

/// User's complete tournament history (live & completed)
final userHistoryTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return service.getUserHistory();
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
