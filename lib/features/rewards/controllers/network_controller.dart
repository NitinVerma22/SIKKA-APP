import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/user/user_service.dart';

class NetworkState {
  final bool isLoading;
  final List<dynamic> level1;
  final List<dynamic> level2;
  final List<dynamic> level3;
  final int totalTeam;
  final int referralBalance;
  final int personalPlaytime;

  NetworkState({
    this.isLoading = false,
    this.level1 = const [],
    this.level2 = const [],
    this.level3 = const [],
    this.totalTeam = 0,
    this.referralBalance = 0,
    this.personalPlaytime = 0,
  });

  NetworkState copyWith({
    bool? isLoading,
    List<dynamic>? level1,
    List<dynamic>? level2,
    List<dynamic>? level3,
    int? totalTeam,
    int? referralBalance,
    int? personalPlaytime,
  }) {
    return NetworkState(
      isLoading: isLoading ?? this.isLoading,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      totalTeam: totalTeam ?? this.totalTeam,
      referralBalance: referralBalance ?? this.referralBalance,
      personalPlaytime: personalPlaytime ?? this.personalPlaytime,
    );
  }
}

class NetworkNotifier extends StateNotifier<NetworkState> {
  final UserService _userService;

  NetworkNotifier(this._userService) : super(NetworkState()) {
    fetchNetwork();
  }

  Future<void> fetchNetwork() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _userService.getMyNetwork();
      if (data != null && data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          referralBalance: data['referralBalance'] ?? 0,
          personalPlaytime: data['personalPlaytime'] ?? 0,
          level1: data['network']?['level1'] ?? [],
          level2: data['network']?['level2'] ?? [],
          level3: data['network']?['level3'] ?? [],
          totalTeam: data['network']?['totalTeam'] ?? 0,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  // We can just instantiate UserService directly or use a provider if it existed globally
  return NetworkNotifier(UserService());
});
