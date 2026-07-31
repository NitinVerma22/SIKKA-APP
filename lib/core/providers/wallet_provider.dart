import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletNotifier extends Notifier<int> {
  @override
  int build() {
    // Initial global balance
    return 150;
  }

  void addCoins(int amount) {
    state += amount;
  }

  void removeCoins(int amount) {
    if (state >= amount) {
      state -= amount;
    } else {
      state = 0;
    }
  }

  bool hasEnough(int amount) => state >= amount;
}

final walletProvider = NotifierProvider<WalletNotifier, int>(() {
  return WalletNotifier();
});
