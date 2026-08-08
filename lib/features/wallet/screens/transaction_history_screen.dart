import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    setState(() => _isLoading = true);
    final data = await ref
        .read(userServiceProvider)
        .getTransactions(page, limit: _pageSize);
    if (mounted) {
      final selectedLanguage = ref.read(languageProvider);
      setState(() {
        _isLoading = false;
        _currentPage = page;
        if (data != null && data['success'] == true) {
          _transactions = _map(data['transactions'], selectedLanguage);
          _totalPages = data['totalPages'] ?? 1;
        }
      });
    }
  }

  List<dynamic> _map(List<dynamic> txList, String language) {
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

      final isWithdrawal = t['type'] == 'withdrawal';
      final title = t['title'] ?? t['description'] ?? (isWithdrawal ? 'Withdrawal' : 'Reward');
      final translatedTitle = _translateTitle(title, language);
      
      filteredList.add({
        'title': translatedTitle.replaceAll('. Ref ID:', '.\nRef ID:'),
        'rewardAmount': t['amount'] ?? t['rewardAmount'] ?? 0,
        'timeAgo': _formatTimeAgo(t['createdAt'] ?? t['timeAgo'], language),
        'type': isWithdrawal ? 'withdrawal' : 'earning',
        'status': _translateStatus(t['status'] ?? 'Completed', language),
      });
    }
    return filteredList;
  }

  String _formatTimeAgo(String? dateStr, String language) {
    if (dateStr == null) return language == 'Hindi' ? 'हाल ही में' : 'Recent';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return language == 'Hindi' ? '${diff.inDays} दिन पहले' : '${diff.inDays}d ago';
      if (diff.inHours > 0) return language == 'Hindi' ? '${diff.inHours} घंटे पहले' : '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return language == 'Hindi' ? '${diff.inMinutes} मिनट पहले' : '${diff.inMinutes}m ago';
      return language == 'Hindi' ? 'अभी-अभी' : 'Just now';
    } catch (_) {
      return language == 'Hindi' ? 'हाल ही में' : 'Recent';
    }
  }

  String _translateStatus(String status, String language) {
    if (language != 'Hindi') return status;
    final lower = status.toLowerCase();
    if (lower.contains('pending approval')) return 'अनुमोदन लंबित';
    if (lower.contains('pending')) return 'लंबित';
    if (lower.contains('completed')) return 'सफल';
    if (lower.contains('failed')) return 'असफल';
    return status;
  }

  String _translateTitle(String title, String language) {
    if (language != 'Hindi') return title;
    final lower = title.toLowerCase();
    if (lower.contains('earned from game') || lower.contains('gameplay reward')) {
      String gameName = '';
      if (lower.contains('math_rush')) {
        gameName = 'मैथ रश';
      } else if (lower.contains('spin_earn')) {
        gameName = 'स्पिन और कमाएं';
      } else if (lower.contains('treasure_grid')) {
        gameName = 'ट्रेजर ग्रिड';
      } else if (lower.contains('emoji_memory')) {
        gameName = 'इमोजी मेमोरी';
      }
      return gameName.isNotEmpty ? 'गेम से कमाई: $gameName' : 'गेमप्ले पुरस्कार';
    }
    if (lower.contains('withdrawal to upi') || lower.contains('withdrawal')) {
      return 'UPI में निकासी';
    }
    if (lower.contains('referral commission') || lower.contains('referral reward') || lower.contains('referred')) {
      return 'रेफरल कमीशन';
    }
    if (lower.contains('registration reward') || lower.contains('register')) {
      return 'पंजीकरण पुरस्कार';
    }
    if (lower.contains('daily streak') || lower.contains('daily checkin') || lower.contains('checkin')) {
      return 'दैनिक स्ट्रीक पुरस्कार';
    }
    if (lower.contains('daily code') || lower.contains('code claim')) {
      return 'दैनिक कोड दावा';
    }
    if (lower.contains('refund')) {
      return 'धनवापसी (Refund)';
    }
    return title;
  }

  IconData _getTxIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('withdraw') || lowercaseTitle.contains('निकासी')) return Icons.outbox_rounded;
    if (lowercaseTitle.contains('link') || lowercaseTitle.contains('visit') || lowercaseTitle.contains('विजिट')) return Icons.link_rounded;
    if (lowercaseTitle.contains('survey') || lowercaseTitle.contains('pollfish') || lowercaseTitle.contains('सर्वे')) return Icons.star_outline_rounded;
    if (lowercaseTitle.contains('streak') || lowercaseTitle.contains('checkin') || lowercaseTitle.contains('स्ट्रीक')) return Icons.water_drop_outlined;
    return Icons.add_circle_outline_rounded;
  }

  Color _getTxColor(String type) {
    return type == 'withdrawal' ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
  }

  Color _getTxBgColor(String type) {
    return type == 'withdrawal' ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('tx_history_title', selectedLanguage),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmpty(selectedLanguage)
              : Column(
                  children: [
                    // Page info header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('page_info', selectedLanguage)
                                .replaceAll('{current}', '$_currentPage')
                                .replaceAll('{total}', '$_totalPages'),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            context.tr('items_per_page', selectedLanguage)
                                .replaceAll('{count}', '$_pageSize'),
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    // Transaction list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount: _transactions.length + (_currentPage == _totalPages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _transactions.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Text(
                                  context.tr('no_more_history', selectedLanguage),
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          }
                          final tx = _transactions[index];
                          final isEarning = tx['type'] == 'earning';
                          final txTitle = tx['title'] ?? 'Transaction';
                          final txAmount = tx['rewardAmount'] ?? 0;
                          final txTime = tx['timeAgo'] ?? 'Recent';
                          final txStatus = tx['status'] ?? 'Completed';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getTxBgColor(tx['type']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getTxIcon(txTitle),
                                    color: _getTxColor(tx['type']),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        txTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            txTime,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                          if (!isEarning) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: txStatus == 'Pending Approval' || txStatus == 'Pending' || txStatus == 'pending' || txStatus == 'अनुमोदन लंबित' || txStatus == 'लंबित'
                                                    ? const Color(0xFFFFF7ED)
                                                    : const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                txStatus,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: txStatus == 'Pending Approval' || txStatus == 'Pending' || txStatus == 'pending' || txStatus == 'अनुमोदन लंबित' || txStatus == 'लंबित'
                                                      ? const Color(0xFFF97316)
                                                      : const Color(0xFF16A34A),
                                                ),
                                              ),
                                            )
                                          ]
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    if (isEarning) ...[
                                      const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 14),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      '${isEarning ? "+" : "-"}$txAmount',
                                      style: TextStyle(
                                        color: isEarning ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Pagination bar at bottom
                    if (_totalPages > 1) _buildPaginationBar(),
                  ],
                ),
    );
  }

  Widget _buildEmpty(String selectedLanguage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(context.tr('no_transactions', selectedLanguage),
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(context.tr('start_playing_earn', selectedLanguage),
              style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    final bool canPrev = _currentPage > 1;
    final bool canNext = _currentPage < _totalPages;

    // Show max 5 page buttons around current page
    int start = (_currentPage - 2).clamp(1, _totalPages);
    int end = (start + 4).clamp(1, _totalPages);
    start = (end - 4).clamp(1, _totalPages);
    final pageNums = List.generate(end - start + 1, (i) => start + i);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pgBtn(
                icon: Icons.chevron_left_rounded,
                onTap: canPrev ? () => _fetchPage(_currentPage - 1) : null,
                enabled: canPrev),
            const SizedBox(width: 4),
            ...pageNums.map((p) => _pgNum(p)),
            const SizedBox(width: 4),
            _pgBtn(
                icon: Icons.chevron_right_rounded,
                onTap: canNext ? () => _fetchPage(_currentPage + 1) : null,
                enabled: canNext),
          ],
        ),
      ),
    );
  }

  Widget _pgBtn(
      {required IconData icon,
      VoidCallback? onTap,
      required bool enabled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLight),
        ),
        child: Icon(icon,
            size: 22, color: enabled ? AppColors.primary : AppColors.textLight),
      ),
    );
  }

  Widget _pgNum(int page) {
    final bool isActive = page == _currentPage;
    return GestureDetector(
      onTap: isActive ? null : () => _fetchPage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  isActive ? AppColors.primary : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
