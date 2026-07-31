import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/notifications/providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Notifications',
          style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notifier.markAsRead(null);
              },
              child: const Text('Mark all read',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          if (state.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () {
                notifier.clearAll();
              },
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  onRefresh: () => notifier.fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final item = state.notifications[index];
                      return _NotificationTile(item: item, notifier: notifier);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: AppColors.textLight.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are all caught up!',
            style: TextStyle(
                color: AppColors.textLight, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final NotificationNotifier notifier;

  const _NotificationTile({required this.item, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          notifier.markAsRead(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED),
            width: item.isRead ? 1.2 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED)
                  .withValues(alpha: item.isRead ? 0.06 : 0.22),
              blurRadius: item.isRead ? 6 : 14,
              spreadRadius: item.isRead ? 0 : 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(item.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(item.type),
                  color: _getIconColor(item.type), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontWeight:
                          item.isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (item.bannerUrl != null &&
                      item.bannerUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.bannerUrl!,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _getTimeAgo(item.createdAt),
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'reward':
        return Icons.stars_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      case 'referral':
        return Icons.people_alt_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'good_news':
        return Icons.emoji_events_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'wishing':
        return Icons.celebration_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'reward':
        return Colors.green.shade600;
      case 'withdrawal':
        return Colors.orange.shade700;
      case 'referral':
        return AppColors.primary;
      case 'announcement':
        return Colors.blue.shade600;
      case 'good_news':
        return Colors.amber.shade700;
      case 'warning':
        return Colors.red.shade600;
      case 'wishing':
        return Colors.purple.shade600;
      default:
        return AppColors.primary;
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
