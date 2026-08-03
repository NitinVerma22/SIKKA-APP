import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/user/user_service.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/widgets/social_join_tasks_widget.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';

class HomeState {
  final bool isLoading;
  final int balance;
  final int totalEarning;
  final int referralEarning;
  final int withdrawalAmount;
  
  final int streakCount;
  final bool hasClaimedToday;
  final List<RewardItem> recentRewards;
  
  // Activity monitoring
  final int gamesMinutesPlayed;
  
  // Claimed milestones (stored as sets of minutes)
  final Set<int> playEarnClaimedMilestones;
  
  // Social tasks
  final Set<String> completedSocialTasks;
  final List<SocialTask> socialTasks;

  // New Daily Tasks status
  final bool dailyCodeTaskCompleted;
  final bool dailyCodeTaskClaimed;
  final bool visitAllTaskCompleted;
  final bool visitAllTaskClaimed;
  final int visitAllTaskTotalLinks;
  final int visitAllTaskVisitedLinks;

  // Daily Streak Resume fields
  final bool canStreakResume;
  final int streakResumeCost;
  final int skippedDaysCount;
  final int streakBeforeSkip;

  HomeState({
    this.isLoading = false,
    required this.balance,
    this.totalEarning = 0,
    this.referralEarning = 0,
    this.withdrawalAmount = 0,
    required this.streakCount,
    required this.hasClaimedToday,
    required this.recentRewards,
    this.gamesMinutesPlayed = 0,
    this.playEarnClaimedMilestones = const {},
    this.completedSocialTasks = const {},
    this.socialTasks = const [],
    this.dailyCodeTaskCompleted = false,
    this.dailyCodeTaskClaimed = false,
    this.visitAllTaskCompleted = false,
    this.visitAllTaskClaimed = false,
    this.visitAllTaskTotalLinks = 0,
    this.visitAllTaskVisitedLinks = 0,
    this.canStreakResume = false,
    this.streakResumeCost = 0,
    this.skippedDaysCount = 0,
    this.streakBeforeSkip = 0,
  });

  HomeState copyWith({
    bool? isLoading,
    int? balance,
    int? totalEarning,
    int? referralEarning,
    int? withdrawalAmount,
    int? streakCount,
    bool? hasClaimedToday,
    List<RewardItem>? recentRewards,
    int? gamesMinutesPlayed,
    Set<int>? playEarnClaimedMilestones,
    Set<String>? completedSocialTasks,
    List<SocialTask>? socialTasks,
    bool? dailyCodeTaskCompleted,
    bool? dailyCodeTaskClaimed,
    bool? visitAllTaskCompleted,
    bool? visitAllTaskClaimed,
    int? visitAllTaskTotalLinks,
    int? visitAllTaskVisitedLinks,
    bool? canStreakResume,
    int? streakResumeCost,
    int? skippedDaysCount,
    int? streakBeforeSkip,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      totalEarning: totalEarning ?? this.totalEarning,
      referralEarning: referralEarning ?? this.referralEarning,
      withdrawalAmount: withdrawalAmount ?? this.withdrawalAmount,
      streakCount: streakCount ?? this.streakCount,
      hasClaimedToday: hasClaimedToday ?? this.hasClaimedToday,
      recentRewards: recentRewards ?? this.recentRewards,
      gamesMinutesPlayed: gamesMinutesPlayed ?? this.gamesMinutesPlayed,
      playEarnClaimedMilestones: playEarnClaimedMilestones ?? this.playEarnClaimedMilestones,
      completedSocialTasks: completedSocialTasks ?? this.completedSocialTasks,
      socialTasks: socialTasks ?? this.socialTasks,
      dailyCodeTaskCompleted: dailyCodeTaskCompleted ?? this.dailyCodeTaskCompleted,
      dailyCodeTaskClaimed: dailyCodeTaskClaimed ?? this.dailyCodeTaskClaimed,
      visitAllTaskCompleted: visitAllTaskCompleted ?? this.visitAllTaskCompleted,
      visitAllTaskClaimed: visitAllTaskClaimed ?? this.visitAllTaskClaimed,
      visitAllTaskTotalLinks: visitAllTaskTotalLinks ?? this.visitAllTaskTotalLinks,
      visitAllTaskVisitedLinks: visitAllTaskVisitedLinks ?? this.visitAllTaskVisitedLinks,
      canStreakResume: canStreakResume ?? this.canStreakResume,
      streakResumeCost: streakResumeCost ?? this.streakResumeCost,
      skippedDaysCount: skippedDaysCount ?? this.skippedDaysCount,
      streakBeforeSkip: streakBeforeSkip ?? this.streakBeforeSkip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'totalEarning': totalEarning,
      'referralEarning': referralEarning,
      'withdrawalAmount': withdrawalAmount,
      'streakCount': streakCount,
      'hasClaimedToday': hasClaimedToday,
      'recentRewards': recentRewards.map((x) => x.toJson()).toList(),
      'gamesMinutesPlayed': gamesMinutesPlayed,
      'playEarnClaimedMilestones': playEarnClaimedMilestones.toList(),
      'completedSocialTasks': completedSocialTasks.toList(),
      'socialTasks': socialTasks.map((x) => {
        'id': x.id,
        'title': x.title,
        'platform': x.platform,
        'link': x.link,
        'coinsReward': x.rewardAmount,
        'isCompleted': x.isCompleted,
      }).toList(),
      'dailyCodeTaskCompleted': dailyCodeTaskCompleted,
      'dailyCodeTaskClaimed': dailyCodeTaskClaimed,
      'visitAllTaskCompleted': visitAllTaskCompleted,
      'visitAllTaskClaimed': visitAllTaskClaimed,
      'visitAllTaskTotalLinks': visitAllTaskTotalLinks,
      'visitAllTaskVisitedLinks': visitAllTaskVisitedLinks,
      'canStreakResume': canStreakResume,
      'streakResumeCost': streakResumeCost,
      'skippedDaysCount': skippedDaysCount,
      'streakBeforeSkip': streakBeforeSkip,
    };
  }

  factory HomeState.fromJson(Map<String, dynamic> json) {
    return HomeState(
      isLoading: false,
      balance: json['balance'] ?? 0,
      totalEarning: json['totalEarning'] ?? 0,
      referralEarning: json['referralEarning'] ?? 0,
      withdrawalAmount: json['withdrawalAmount'] ?? 0,
      streakCount: json['streakCount'] ?? 0,
      hasClaimedToday: json['hasClaimedToday'] ?? false,
      recentRewards: (json['recentRewards'] as List<dynamic>?)
              ?.map((x) => RewardItem.fromJson(x))
              .toList() ??
          [],
      gamesMinutesPlayed: json['gamesMinutesPlayed'] ?? 0,
      playEarnClaimedMilestones:
          Set<int>.from(json['playEarnClaimedMilestones'] ?? []),
      completedSocialTasks: Set<String>.from(json['completedSocialTasks'] ?? []),
      socialTasks: (json['socialTasks'] as List<dynamic>?)
              ?.map((x) => SocialTask.fromJson(x))
              .toList() ??
          [],
      dailyCodeTaskCompleted: json['dailyCodeTaskCompleted'] ?? false,
      dailyCodeTaskClaimed: json['dailyCodeTaskClaimed'] ?? false,
      visitAllTaskCompleted: json['visitAllTaskCompleted'] ?? false,
      visitAllTaskClaimed: json['visitAllTaskClaimed'] ?? false,
      visitAllTaskTotalLinks: json['visitAllTaskTotalLinks'] ?? 0,
      visitAllTaskVisitedLinks: json['visitAllTaskVisitedLinks'] ?? 0,
      canStreakResume: json['canStreakResume'] ?? false,
      streakResumeCost: json['streakResumeCost'] ?? 0,
      skippedDaysCount: json['skippedDaysCount'] ?? 0,
      streakBeforeSkip: json['streakBeforeSkip'] ?? 0,
    );
  }
}

class RewardItem {
  final String title;
  final int rewardAmount;
  final String timeAgo;
  final bool isClaim;
  final String status;
  final String type;

  RewardItem({
    required this.title,
    required this.rewardAmount,
    required this.timeAgo,
    this.isClaim = true,
    this.status = 'Completed',
    this.type = 'earning',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'rewardAmount': rewardAmount,
      'timeAgo': timeAgo,
      'isClaim': isClaim,
      'status': status,
      'type': type,
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      title: json['title'] ?? '',
      rewardAmount: json['rewardAmount'] ?? 0,
      timeAgo: json['timeAgo'] ?? '',
      isClaim: json['isClaim'] ?? true,
      status: json['status'] ?? 'Completed',
      type: json['type'] ?? 'earning',
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final UserService _userService;
  final Ref _ref;

  HomeNotifier(this._userService, this._ref)
      : super(
          HomeState(
            isLoading: true,
            balance: 0,
            totalEarning: 0,
            referralEarning: 0,
            withdrawalAmount: 0,
            streakCount: 0,
            hasClaimedToday: false,
            recentRewards: [],
            gamesMinutesPlayed: 0,  
          ),
        ) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final data = await _userService.getHomeState();
      if (data != null && data['success'] == true) {
        state = HomeState.fromJson(data).copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
        throw Exception('Failed to load home state');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Reload explicitly
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    await _loadState();
    if (!silent) {
      await _ref.read(userProvider.notifier).refresh(silent: true).catchError((_) {});
    }
  }

  /// Claims daily streak securely from backend
  Future<bool> claimDailyStreak(int coins, int day) async {
    if (state.hasClaimedToday) return false;

    final success = await _userService.claimDailyStreak();

    if (success) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
      return true;
    }
    return false;
  }

  /// Resumes daily streak by paying fee from backend
  Future<bool> resumeDailyStreak() async {
    final result = await _userService.resumeDailyStreak();
    if (result != null && result['success'] == true) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
      return true;
    }
    return false;
  }
  
  void claimPlayEarn(int minutes, int rewardAmount) {
    if (state.playEarnClaimedMilestones.contains(minutes)) return;

    state = state.copyWith(
      balance: state.balance + rewardAmount,
      totalEarning: state.totalEarning + rewardAmount,
      playEarnClaimedMilestones: {...state.playEarnClaimedMilestones, minutes},
    );
  }

  Future<bool> claimDailyCodeTask(int rewardAmount) async {
    if (state.dailyCodeTaskClaimed) return false;

    final success = await _userService.claimMilestone('daily_code_task', 0);

    if (success) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged, SyncEvent.tasksUpdated]);
      return true;
    }
    return false;
  }

  Future<bool> claimVisitAllLinksTask(int rewardAmount) async {
    if (state.visitAllTaskClaimed) return false;

    final success = await _userService.claimMilestone('visit_all_task', 0);

    if (success) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged, SyncEvent.tasksUpdated]);
      return true;
    }
    return false;
  }

  void completeSocialTask(String taskId, int rewardAmount) {
    if (state.completedSocialTasks.contains(taskId)) return;

    final updatedTasks = state.socialTasks.map((t) {
      if (t.id == taskId) {
        return SocialTask(
          id: t.id,
          title: t.title,
          subtitle: t.subtitle,
          icon: t.icon,
          iconColor: t.iconColor,
          rewardAmount: t.rewardAmount,
          isCompleted: true,
          platform: t.platform,
          link: t.link,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      balance: state.balance + rewardAmount,
      totalEarning: state.totalEarning + rewardAmount,
      completedSocialTasks: {...state.completedSocialTasks, taskId},
      socialTasks: updatedTasks,
    );
  }

  Future<bool> requestWithdrawal(int coinsAmount, String upiId, String name, {String earningType = 'self'}) async {
    if (earningType == 'self') {
      if (state.balance < coinsAmount) return false;
    } else {
      if (state.referralEarning < coinsAmount) return false;
    }

    final success = await _userService.requestWithdrawal(coinsAmount, upiId, earningType: earningType);
    if (success) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
      return true;
    }
    return false;
  }

  void claimSurvey(String title, int rewardAmount) {
    state = state.copyWith(
      balance: state.balance + rewardAmount,
      totalEarning: state.totalEarning + rewardAmount,
    );
  }

  // Activity tracking
  void incrementGamesTime() {
    state = state.copyWith(gamesMinutesPlayed: state.gamesMinutesPlayed + 1);
    _userService.logUsage(1, type: 'games');
  }

  /// Reset claim (for test/interaction replay)
  void resetClaim() {
    state = state.copyWith(hasClaimedToday: false);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return HomeNotifier(userService, ref);
});
