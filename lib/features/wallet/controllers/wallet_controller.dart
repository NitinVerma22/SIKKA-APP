import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/user/user_service.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';

class WalletState {
  final bool isLoading;
  final Map<String, dynamic>? stats;
  final List<dynamic> transactions;
  final String? error;

  WalletState({
    this.isLoading = false,
    this.stats,
    this.transactions = const [],
    this.error,
  });

  WalletState copyWith({
    bool? isLoading,
    Map<String, dynamic>? stats,
    List<dynamic>? transactions,
    String? error,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final UserService _userService;
  final Ref _ref;
  bool _isFetching = false;

  WalletNotifier(this._userService, this._ref) : super(WalletState());

  Future<void> fetchWalletData() async {
    if (_isFetching) return;
    _isFetching = true;

    final isAlreadyLoaded = state.stats != null && state.transactions.isNotEmpty;
    
    if (!isAlreadyLoaded) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final statsFuture = _userService.getWalletStats();
      final txFuture = _userService.getTransactions(1, limit: 5);

      final results = await Future.wait([statsFuture, txFuture]);
      final stats = results[0];
      final txData = results[1];

      List<dynamic> mappedTx = [];
      if (txData != null && txData['success'] == true) {
        mappedTx = _mapTransactions(txData['transactions']);
      } else {
        // Fallback to homeState recent rewards
        final homeState = _ref.read(homeProvider);
        mappedTx = _mapTransactions(
          homeState.recentRewards.map((r) => r.toJson()).toList().take(5).toList(),
        );
      }

      state = WalletState(
        isLoading: false,
        stats: stats,
        transactions: mappedTx,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  List<dynamic> _mapTransactions(List<dynamic> txList) {
    final now = DateTime.now();
    final List<dynamic> filteredList = [];

    for (final t in txList) {
      final dateStr = t['createdAt'];
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          if (now.difference(date).inDays >= 3) {
            continue; // Skip transactions older than 3 days
          }
        } catch (_) {}
      }

      final rawAmount = (t['amount'] ?? t['rewardAmount'] ?? 0) as num;
      final isSpend = rawAmount < 0 || t['type'] == 'withdrawal';
      final absoluteAmount = rawAmount < 0 ? -rawAmount : rawAmount;
        
      final title = t['title'] ?? t['description'] ?? (isSpend ? 'Spent' : 'Reward');
      filteredList.add({
        'title': title.replaceAll('. Ref ID:', '.\nRef ID:'),
        'rewardAmount': absoluteAmount,
        'timeAgo': _formatTimeAgo(t['createdAt'] ?? t['timeAgo']),
        'type': isSpend ? 'spend' : 'earning',
        'status': t['status'] ?? 'Completed',
      });
    }
    return filteredList;
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return dateStr;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return WalletNotifier(userService, ref);
});
