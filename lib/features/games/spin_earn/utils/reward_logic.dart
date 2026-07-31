import 'dart:math';

/// Defines the possible rewards on the spin wheel.
class RewardItem {
  final int coins;
  final String label;

  const RewardItem(this.coins, this.label);
}

class RewardLogic {
  static final Random _rng = Random();

  /// The wheel layout (used to draw the segments).
  static const List<RewardItem> wheelSlots = [
    RewardItem(1, '1'),
    RewardItem(10, '10'),
    RewardItem(2, '2'),
    RewardItem(15, '15'),
    RewardItem(3, '3'),
    RewardItem(30, '30'), // Ultra rare
    RewardItem(5, '5'),
    RewardItem(20, '20'),
    RewardItem(7, '7'),
  ];

  /// Returns the index of the drawn reward based on weighted probabilities.
  /// 
  /// 1-5 coins: Very Common (~80%)
  /// 7-10 coins: Medium (~15%)
  /// 15-20 coins: Rare (~4.999%)
  /// 30 coins: Ultra Rare (0.001%)
  static int getRandomRewardIndex() {
    // Generate a random double between 0.0 and 100.0
    final double roll = _rng.nextDouble() * 100.0;

    int rewardAmount;

    if (roll < 0.001) {
      rewardAmount = 30; // 0.001%
    } else if (roll < 5.0) {
      rewardAmount = _rng.nextBool() ? 15 : 20; // 4.999%
    } else if (roll < 20.0) {
      rewardAmount = _rng.nextBool() ? 7 : 10; // 15%
    } else {
      // 80% chance for 1, 2, 3, or 5
      final commonRoll = _rng.nextInt(4);
      switch (commonRoll) {
        case 0:
          rewardAmount = 1;
          break;
        case 1:
          rewardAmount = 2;
          break;
        case 2:
          rewardAmount = 3;
          break;
        default:
          rewardAmount = 5;
      }
    }

    // Find the index of this reward in the wheel slots
    final index = wheelSlots.indexWhere((item) => item.coins == rewardAmount);
    return index >= 0 ? index : 0;
  }
}
