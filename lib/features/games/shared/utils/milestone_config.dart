class MilestoneConfig {
  final int id;
  final int startLevel;
  final int endLevel;
  final int totalReward;
  final Map<int, int> checkpoints; // Level -> Reward Coins

  const MilestoneConfig({
    required this.id,
    required this.startLevel,
    required this.endLevel,
    required this.totalReward,
    required this.checkpoints,
  });
}

class MilestonesData {
  static const List<MilestoneConfig> milestones = [
    MilestoneConfig(
      id: 1, startLevel: 1, endLevel: 15, totalReward: 200,
      checkpoints: {5: 40, 10: 55, 15: 105},
    ),
    MilestoneConfig(
      id: 2, startLevel: 16, endLevel: 30, totalReward: 250,
      checkpoints: {20: 45, 25: 70, 30: 135},
    ),
    MilestoneConfig(
      id: 3, startLevel: 31, endLevel: 50, totalReward: 280,
      checkpoints: {35: 35, 40: 50, 45: 65, 50: 130},
    ),
    MilestoneConfig(
      id: 4, startLevel: 51, endLevel: 75, totalReward: 350,
      checkpoints: {55: 35, 60: 45, 65: 55, 70: 70, 75: 145},
    ),
    MilestoneConfig(
      id: 5, startLevel: 76, endLevel: 100, totalReward: 400,
      checkpoints: {80: 40, 85: 50, 90: 60, 95: 75, 100: 175},
    ),
    MilestoneConfig(
      id: 6, startLevel: 101, endLevel: 125, totalReward: 600,
      checkpoints: {105: 50, 110: 75, 115: 100, 120: 125, 125: 250},
    ),
    MilestoneConfig(
      id: 7, startLevel: 126, endLevel: 150, totalReward: 650,
      checkpoints: {130: 50, 135: 80, 140: 110, 145: 140, 150: 270},
    ),
    MilestoneConfig(
      id: 8, startLevel: 151, endLevel: 200, totalReward: 850,
      checkpoints: {160: 70, 170: 100, 180: 130, 190: 170, 200: 380},
    ),
    MilestoneConfig(
      id: 9, startLevel: 201, endLevel: 250, totalReward: 900,
      checkpoints: {210: 75, 220: 110, 230: 140, 240: 175, 250: 400},
    ),
    MilestoneConfig(
      id: 10, startLevel: 251, endLevel: 300, totalReward: 1000,
      checkpoints: {260: 80, 270: 120, 280: 160, 290: 190, 300: 450},
    ),
  ];

  static MilestoneConfig? getMilestoneForLevel(int level) {
    for (var m in milestones) {
      if (level >= m.startLevel && level <= m.endLevel) {
        return m;
      }
    }
    return null;
  }
}
