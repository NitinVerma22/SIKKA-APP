import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double speed;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.speed = 30.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted || !_scrollController.hasClients) return;
        final currentOffset = _scrollController.offset;
        if (currentOffset >= maxScroll) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(currentOffset + (widget.speed * 0.05));
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Text(widget.text, style: widget.style),
            const SizedBox(width: 100),
            Text(widget.text, style: widget.style),
          ],
        ),
      ),
    );
  }
}

class TodayTasksScreen extends ConsumerStatefulWidget {
  const TodayTasksScreen({super.key});

  @override
  ConsumerState<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends ConsumerState<TodayTasksScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user task progress immediately when opening the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeProvider.notifier).refresh();
      }
    });
  }

  void _handleDailyCodeTaskClaim(BuildContext context, int amount) async {
    final success = await ref.read(homeProvider.notifier).claimDailyCodeTask(amount);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Claimed $amount coins for Daily Code Task!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleVisitAllLinksClaim(BuildContext context, int amount) async {
    final success = await ref.read(homeProvider.notifier).claimVisitAllLinksTask(amount);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Claimed $amount coins for visiting all links!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handlePlayClaim(BuildContext context, int minutes, int amount) async {
    ref.read(homeProvider.notifier).claimPlayEarn(minutes, amount);
    await ref.read(userProvider.notifier).claimReward(amount, 'earning', 'Played Games for $minutes mins');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Claimed $amount coins for playing $minutes mins!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildOfferCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String reward,
    required IconData icon,
    required LinearGradient gradient,
    required Widget actionWidget,
    double? progress,
    String? progressText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: AppColors.premiumShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         title,
                         style: const TextStyle(
                           color: AppColors.textPrimary,
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 3),
                       Text(
                         subtitle,
                         style: const TextStyle(
                           color: AppColors.textSecondary,
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                   decoration: BoxDecoration(
                     color: AppColors.primary.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 14),
                       const SizedBox(width: 4),
                       Text(
                         reward,
                         style: const TextStyle(
                           color: AppColors.primary,
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
             if (progress != null || progressText != null) ...[
               const SizedBox(height: 14),
               Row(
                 children: [
                   if (progress != null)
                     Expanded(
                       child: Stack(
                         children: [
                           Container(
                             height: 8,
                             decoration: BoxDecoration(
                               color: AppColors.borderLight,
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                           FractionallySizedBox(
                             widthFactor: progress.clamp(0.0, 1.0),
                             child: Container(
                               height: 8,
                               decoration: BoxDecoration(
                                 gradient: gradient,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   if (progressText != null) ...[
                     const SizedBox(width: 12),
                     Text(
                       progressText,
                       style: const TextStyle(
                         color: AppColors.textSecondary,
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ]
                 ],
               ),
             ],
             const SizedBox(height: 14),
             SizedBox(
               width: double.infinity,
               height: 42,
               child: actionWidget,
             ),
           ],
         ),
       ),
     );
   }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final userData = userState.userData ?? {};
    final homeState = ref.watch(homeProvider);
    final balance = userData['balance'] ?? homeState.balance;
    final referralEarning = userData['referralBalance'] ?? homeState.referralEarning;
    final configState = ref.watch(appConfigProvider);
    final config = configState.config;
    final selectedLanguage = ref.watch(languageProvider);

    // Retrieve configs
    final dailyCodeCoins = config?['dailyCodeTaskCoins'] ?? 10;
    final visitAllCoins = config?['visitAllTaskCoins'] ?? 30;
    
    final playM1Mins = config?['playM1Mins'] ?? 20;
    final playM1Coins = config?['playM1Coins'] ?? 40;
    
    final playM2Mins = config?['playM2Mins'] ?? 50;
    final playM2Coins = config?['playM2Coins'] ?? 90;
    
    final playM3Mins = config?['playM3Mins'] ?? 99;
    final playM3Coins = config?['playM3Coins'] ?? 180;

    final referralCoins = config?['referralBonus'] ?? 500;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          context.tr('daily_tasks_offer_wall', selectedLanguage),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: homeState.isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
        : RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.premiumShadow,
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('task_wallet_balance', selectedLanguage),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('coins_suffix', selectedLanguage).replaceAll('{coins}', '${balance + referralEarning}'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: AppColors.yellowGlow,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MarqueeText(
                            text: context.tr('complete_tasks_daily_note', selectedLanguage),
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      context.tr('active_offers_milestones', selectedLanguage),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Task 1: Claim Daily Code
                  _buildOfferCard(
                    context: context,
                    title: context.tr('claim_daily_code', selectedLanguage),
                    subtitle: context.tr('claim_daily_code_desc', selectedLanguage),
                    reward: '+$dailyCodeCoins',
                    icon: Icons.vpn_key_rounded,
                    gradient: AppColors.primaryGradient,
                    actionWidget: homeState.dailyCodeTaskClaimed
                        ? PremiumButton(
                            text: context.tr('claimed_checkmark', selectedLanguage),
                            borderRadius: 8,
                            customGradient: const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
                            onTap: () {},
                          )
                        : homeState.dailyCodeTaskCompleted
                            ? PremiumButton(
                                text: context.tr('claim_coins_action', selectedLanguage).replaceAll('{coins}', '$dailyCodeCoins'),
                                borderRadius: 8,
                                customGradient: AppColors.goldGradient,
                                onTap: () => _handleDailyCodeTaskClaim(context, dailyCodeCoins),
                              )
                            : PremiumButton(
                                text: context.tr('go_to_daily_code', selectedLanguage),
                                borderRadius: 8,
                                customGradient: AppColors.cyanGradient,
                                onTap: () async {
                                  await context.push('/home/daily_code');
                                  if (mounted) {
                                    ref.read(homeProvider.notifier).refresh();
                                  }
                                },
                              ),
                  ),

                  // Task 2: Visit & Earn Links Explorer
                  _buildOfferCard(
                    context: context,
                    title: context.tr('links_explorer', selectedLanguage),
                    subtitle: context.tr('links_explorer_desc', selectedLanguage),
                    reward: '+$visitAllCoins',
                    icon: Icons.public_rounded,
                    gradient: AppColors.cyanGradient,
                    progress: homeState.visitAllTaskTotalLinks > 0 
                        ? homeState.visitAllTaskVisitedLinks / homeState.visitAllTaskTotalLinks 
                        : 0.0,
                    progressText: context.tr('links_progress', selectedLanguage)
                        .replaceAll('{current}', '${homeState.visitAllTaskVisitedLinks}')
                        .replaceAll('{total}', '${homeState.visitAllTaskTotalLinks}'),
                    actionWidget: homeState.visitAllTaskClaimed
                        ? PremiumButton(
                            text: context.tr('claimed_checkmark', selectedLanguage),
                            borderRadius: 8,
                            customGradient: const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
                            onTap: () {},
                          )
                        : homeState.visitAllTaskCompleted
                            ? PremiumButton(
                                text: context.tr('claim_coins_action', selectedLanguage).replaceAll('{coins}', '$visitAllCoins'),
                                borderRadius: 8,
                                customGradient: AppColors.goldGradient,
                                onTap: () => _handleVisitAllLinksClaim(context, visitAllCoins),
                              )
                            : PremiumButton(
                                text: context.tr('visit_links', selectedLanguage),
                                borderRadius: 8,
                                customGradient: AppColors.primaryGradient,
                                onTap: () async {
                                  await context.push('/home/visit_earn');
                                  if (mounted) {
                                    ref.read(homeProvider.notifier).refresh();
                                  }
                                },
                              ),
                  ),

                  // Task 3: Play Games 20 Min Milestone
                  _buildOfferCard(
                    context: context,
                    title: context.tr('bronze_play_milestone', selectedLanguage),
                    subtitle: context.tr('play_milestone_desc', selectedLanguage).replaceAll('{minutes}', '$playM1Mins'),
                    reward: '+$playM1Coins',
                    icon: Icons.sports_esports_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCD7F32), Color(0xFFE5A93C)],
                    ),
                    progress: homeState.gamesMinutesPlayed / playM1Mins,
                    progressText: context.tr('mins_progress', selectedLanguage)
                        .replaceAll('{current}', '${homeState.gamesMinutesPlayed}')
                        .replaceAll('{total}', '$playM1Mins'),
                    actionWidget: homeState.playEarnClaimedMilestones.contains(playM1Mins)
                        ? PremiumButton(
                            text: context.tr('claimed_checkmark', selectedLanguage),
                            borderRadius: 8,
                            customGradient: const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
                            onTap: () {},
                          )
                        : homeState.gamesMinutesPlayed >= playM1Mins
                            ? PremiumButton(
                                text: context.tr('claim_coins_action', selectedLanguage).replaceAll('{coins}', '$playM1Coins'),
                                borderRadius: 8,
                                customGradient: AppColors.goldGradient,
                                onTap: () => _handlePlayClaim(context, playM1Mins, playM1Coins),
                              )
                            : PremiumButton(
                                text: context.tr('play_games_now', selectedLanguage),
                                borderRadius: 8,
                                customGradient: AppColors.cyanGradient,
                                onTap: () async {
                                  await context.push('/games');
                                  if (mounted) {
                                    ref.read(homeProvider.notifier).refresh();
                                  }
                                },
                              ),
                  ),

                  // Task 4: Play Games 50 Min Milestone
                  _buildOfferCard(
                    context: context,
                    title: context.tr('silver_play_milestone', selectedLanguage),
                    subtitle: context.tr('play_milestone_desc', selectedLanguage).replaceAll('{minutes}', '$playM2Mins'),
                    reward: '+$playM2Coins',
                    icon: Icons.sports_esports_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC0C0C0), Color(0xFFE0E0E0)],
                    ),
                    progress: homeState.gamesMinutesPlayed / playM2Mins,
                    progressText: context.tr('mins_progress', selectedLanguage)
                        .replaceAll('{current}', '${homeState.gamesMinutesPlayed}')
                        .replaceAll('{total}', '$playM2Mins'),
                    actionWidget: homeState.playEarnClaimedMilestones.contains(playM2Mins)
                        ? PremiumButton(
                            text: context.tr('claimed_checkmark', selectedLanguage),
                            borderRadius: 8,
                            customGradient: const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
                            onTap: () {},
                          )
                        : homeState.gamesMinutesPlayed >= playM2Mins
                            ? PremiumButton(
                                text: context.tr('claim_coins_action', selectedLanguage).replaceAll('{coins}', '$playM2Coins'),
                                borderRadius: 8,
                                customGradient: AppColors.goldGradient,
                                onTap: () => _handlePlayClaim(context, playM2Mins, playM2Coins),
                              )
                            : PremiumButton(
                                text: context.tr('keep_playing', selectedLanguage),
                                borderRadius: 8,
                                customGradient: AppColors.cyanGradient,
                                onTap: () async {
                                  await context.push('/games');
                                  if (mounted) {
                                    ref.read(homeProvider.notifier).refresh();
                                  }
                                },
                              ),
                  ),

                  // Task 5: Play Games 99 Min Milestone
                  _buildOfferCard(
                    context: context,
                    title: context.tr('gold_play_milestone', selectedLanguage),
                    subtitle: context.tr('play_milestone_desc', selectedLanguage).replaceAll('{minutes}', '$playM3Mins'),
                    reward: '+$playM3Coins',
                    icon: Icons.sports_esports_rounded,
                    gradient: AppColors.goldGradient,
                    progress: homeState.gamesMinutesPlayed / playM3Mins,
                    progressText: context.tr('mins_progress', selectedLanguage)
                        .replaceAll('{current}', '${homeState.gamesMinutesPlayed}')
                        .replaceAll('{total}', '$playM3Mins'),
                    actionWidget: homeState.playEarnClaimedMilestones.contains(playM3Mins)
                        ? PremiumButton(
                            text: context.tr('claimed_checkmark', selectedLanguage),
                            borderRadius: 8,
                            customGradient: const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
                            onTap: () {},
                          )
                        : homeState.gamesMinutesPlayed >= playM3Mins
                            ? PremiumButton(
                                text: context.tr('claim_coins_action', selectedLanguage).replaceAll('{coins}', '$playM3Coins'),
                                borderRadius: 8,
                                customGradient: AppColors.goldGradient,
                                onTap: () => _handlePlayClaim(context, playM3Mins, playM3Coins),
                              )
                            : PremiumButton(
                                text: context.tr('go_to_games', selectedLanguage),
                                borderRadius: 8,
                                customGradient: AppColors.cyanGradient,
                                onTap: () async {
                                  await context.push('/games');
                                  if (mounted) {
                                    ref.read(homeProvider.notifier).refresh();
                                  }
                                },
                              ),
                  ),

                  // Task 6: Refer a Friend
                  _buildOfferCard(
                    context: context,
                    title: context.tr('invite_friends_earn', selectedLanguage),
                    subtitle: context.tr('invite_friends_desc', selectedLanguage),
                    reward: '+$referralCoins',
                    icon: Icons.people_rounded,
                    gradient: AppColors.primaryGradient,
                    actionWidget: PremiumButton(
                      text: context.tr('invite_friends_action', selectedLanguage),
                      borderRadius: 8,
                      customGradient: AppColors.goldGradient,
                      onTap: () async {
                        await context.push('/my_network');
                        if (mounted) {
                          ref.read(homeProvider.notifier).refresh();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
