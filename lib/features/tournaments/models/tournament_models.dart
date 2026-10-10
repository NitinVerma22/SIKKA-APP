
enum TournamentStatus {
  upcoming,
  live,
  completed,
  cancelled;

  static TournamentStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'LIVE':
        return TournamentStatus.live;
      case 'COMPLETED':
        return TournamentStatus.completed;
      case 'CANCELLED':
        return TournamentStatus.cancelled;
      case 'UPCOMING':
      default:
        return TournamentStatus.upcoming;
    }
  }

  String toDbString() {
    switch (this) {
      case TournamentStatus.live:
        return 'LIVE';
      case TournamentStatus.completed:
        return 'COMPLETED';
      case TournamentStatus.cancelled:
        return 'CANCELLED';
      case TournamentStatus.upcoming:
        return 'UPCOMING';
    }
  }
}

enum TournamentEntryType {
  free,
  paidCoins;

  static TournamentEntryType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'COINS':
      case 'PAID_COINS':
      case 'PAID':
        return TournamentEntryType.paidCoins;
      case 'FREE':
      default:
        return TournamentEntryType.free;
    }
  }

  String toDbString() {
    switch (this) {
      case TournamentEntryType.paidCoins:
        return 'COINS';
      case TournamentEntryType.free:
        return 'FREE';
    }
  }
}

class PrizeTier {
  final int rankMin;
  final int rankMax;
  final int prize;
  final int? prizeRupees;

  const PrizeTier({
    required this.rankMin,
    required this.rankMax,
    required this.prize,
    this.prizeRupees,
  });

  factory PrizeTier.fromJson(Map<String, dynamic> json) {
    return PrizeTier(
      rankMin: (json['rankMin'] as num?)?.toInt() ?? 1,
      rankMax: (json['rankMax'] as num?)?.toInt() ?? 1,
      prize: (json['prize'] as num?)?.toInt() ?? 0,
      prizeRupees: (json['prizeRupees'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rankMin': rankMin,
    'rankMax': rankMax,
    'prize': prize,
    'prizeRupees': prizeRupees,
  };

  int getCalculatedRupees(int totalPoolCoins, int totalPoolRupees) {
    if (prizeRupees != null && prizeRupees! > 0) return prizeRupees!;
    if (totalPoolCoins > 0 && totalPoolRupees > 0) {
      return ((prize / totalPoolCoins) * totalPoolRupees).round();
    }
    return 0;
  }

  String get label {
    if (rankMin == rankMax) {
      return 'Rank #$rankMin';
    }
    return 'Rank #$rankMin - #$rankMax';
  }
}

class UserParticipation {
  final String id;
  final int score;
  final int? rank;
  final DateTime joinedAt;

  const UserParticipation({
    required this.id,
    required this.score,
    this.rank,
    required this.joinedAt,
  });

  factory UserParticipation.fromJson(Map<String, dynamic> json) {
    return UserParticipation(
      id: json['id']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Tournament {
  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final String? tag;
  final TournamentEntryType entryType;
  final int entryFeeCoins;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> allowedGames;
  final int prizePool;
  final int prizePoolRupees;
  final List<PrizeTier> prizeStructure;
  final int minParticipants;
  final int? maxParticipants;
  final int currentParticipants;
  final TournamentStatus status;
  final bool isJoinedExplicit;
  final UserParticipation? userParticipation;

  const Tournament({
    required this.id,
    required this.title,
    this.description,
    this.bannerUrl,
    this.tag,
    required this.entryType,
    required this.entryFeeCoins,
    required this.startTime,
    required this.endTime,
    required this.allowedGames,
    required this.prizePool,
    this.prizePoolRupees = 0,
    required this.prizeStructure,
    required this.minParticipants,
    this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    this.isJoinedExplicit = false,
    this.userParticipation,
  });

  bool get isJoined => isJoinedExplicit || userParticipation != null;

  bool get isLive => status == TournamentStatus.live;
  bool get isUpcoming => status == TournamentStatus.upcoming;
  bool get isCompleted => status == TournamentStatus.completed;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (isUpcoming) {
      return startTime.isAfter(now) ? startTime.difference(now) : Duration.zero;
    }
    if (isLive) {
      return endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
    }
    return Duration.zero;
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    var rawPrizes = json['prizeStructure'];
    List<PrizeTier> prizes = [];
    if (rawPrizes is List) {
      prizes = rawPrizes
          .map((p) => PrizeTier.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    var rawGames = json['allowedGames'];
    List<String> games = [];
    if (rawGames is List) {
      games = rawGames.map((g) => g.toString()).toList();
    }

    final bool rawIsJoined = json['isJoined'] == true ||
        (json['userStanding'] is Map && json['userStanding']['isJoined'] == true) ||
        json['userParticipation'] != null;

    UserParticipation? userPart;
    if (json['userParticipation'] != null) {
      userPart = UserParticipation.fromJson(json['userParticipation'] as Map<String, dynamic>);
    } else if (json['userStanding'] is Map && json['userStanding']['isJoined'] == true) {
      userPart = UserParticipation(
        id: json['id']?.toString() ?? '',
        score: (json['userStanding']['score'] as num?)?.toInt() ?? 0,
        rank: (json['userStanding']['rank'] as num?)?.toInt(),
        joinedAt: json['userStanding']['joinedAt'] != null
            ? DateTime.tryParse(json['userStanding']['joinedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } else if (rawIsJoined) {
      userPart = UserParticipation(
        id: json['id']?.toString() ?? '',
        score: (json['myScore'] as num?)?.toInt() ?? 0,
        joinedAt: DateTime.now(),
      );
    }

    return Tournament(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tournament',
      description: json['description']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      tag: json['tag']?.toString(),
      entryType: TournamentEntryType.fromString(json['entryType']?.toString() ?? 'FREE'),
      entryFeeCoins: ((json['entryFeeCoins'] ?? json['entryFee']) as num?)?.toInt() ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      allowedGames: games,
      prizePool: (json['prizePool'] as num?)?.toInt() ?? 0,
      prizePoolRupees: (json['prizePoolRupees'] as num?)?.toInt() ?? 0,
      prizeStructure: prizes,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? 2,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      currentParticipants: ((json['currentParticipants'] ?? json['participantCount']) as num?)?.toInt() ?? 0,
      status: TournamentStatus.fromString(json['status']?.toString() ?? 'UPCOMING'),
      isJoinedExplicit: rawIsJoined,
      userParticipation: userPart,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int score;
  final int prize;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.score,
    required this.prize,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Player',
      userAvatar: json['userAvatar']?.toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      prize: (json['prize'] as num?)?.toInt() ?? 0,
    );
  }
}

class TournamentLeaderboardData {
  final String tournamentId;
  final String title;
  final int prizePool;
  final TournamentStatus status;
  final DateTime endTime;
  final List<String> allowedGames;
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? userRank;
  final int totalParticipants;
  final bool isLive;

  const TournamentLeaderboardData({
    required this.tournamentId,
    required this.title,
    required this.prizePool,
    required this.status,
    required this.endTime,
    required this.allowedGames,
    required this.leaderboard,
    this.userRank,
    required this.totalParticipants,
    required this.isLive,
  });

  factory TournamentLeaderboardData.fromJson(Map<String, dynamic> json) {
    final tMap = (json['tournament'] as Map<String, dynamic>?) ?? {};
    final rawLb = json['leaderboard'];
    List<LeaderboardEntry> lbList = [];
    if (rawLb is List) {
      lbList = rawLb
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    LeaderboardEntry? uRank;
    if (json['userRank'] != null) {
      uRank = LeaderboardEntry.fromJson(json['userRank'] as Map<String, dynamic>);
    }

    var rawGames = tMap['allowedGames'];
    List<String> games = [];
    if (rawGames is List) {
      games = rawGames.map((g) => g.toString()).toList();
    }

    return TournamentLeaderboardData(
      tournamentId: tMap['id']?.toString() ?? '',
      title: tMap['title']?.toString() ?? 'Tournament Leaderboard',
      prizePool: (tMap['prizePool'] as num?)?.toInt() ?? 0,
      status: TournamentStatus.fromString(tMap['status']?.toString() ?? 'LIVE'),
      endTime: tMap['endTime'] != null
          ? DateTime.tryParse(tMap['endTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      allowedGames: games,
      leaderboard: lbList,
      userRank: uRank,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? lbList.length,
      isLive: json['isLive'] == true,
    );
  }
}
