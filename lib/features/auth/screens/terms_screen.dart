import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Acceptance of Terms'),
            _buildParagraph(
                'By creating an account and using SikkaPlay, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our app.'),
            const SizedBox(height: 24),
            _buildSectionHeader('2. Account Rules & Banning'),
            _buildParagraph(
                '• You must use a single device for a single account. Multiple accounts on the same device are strictly prohibited.\n'
                '• Use of Emulators, Rooted/Jailbroken devices, or Auto-Clickers is strictly prohibited.\n'
                '• Using VPNs or Proxies to bypass region restrictions or alter ads will result in an immediate and permanent ban.\n'
                '• Any attempt to hack, modify, or cheat the system will result in the forfeiture of all earnings and account termination.'),
            const SizedBox(height: 24),
            _buildSectionHeader('3. Earnings & Withdrawals'),
            _buildParagraph(
                '• SikkaPlay coins are virtual currency and hold no real-world value outside of the app until withdrawn.\n'
                '• Withdrawal requests are subject to review. We reserve the right to reject withdrawals if fraudulent activity is detected.\n'
                '• Ensure your UPI ID is correct. We are not responsible for funds sent to incorrect IDs provided by the user.\n'
                '• The minimum withdrawal limits and processing times may change at our discretion.'),
            const SizedBox(height: 24),
            _buildSectionHeader('4. Referral Program'),
            _buildParagraph(
                '• You may invite friends using your unique referral code.\n'
                '• Self-referrals, fake accounts, or spamming referral codes on unauthorized platforms will lead to account suspension.\n'
                '• Referral bonuses are credited only when the referred user completes the required milestones.'),
            const SizedBox(height: 24),
            _buildSectionHeader('5. Privacy Policy'),
            _buildParagraph(
                '• We collect basic information (like phone numbers, device IDs, and usage analytics) to provide and improve our services.\n'
                '• We do not sell your personal data to third parties.\n'
                '• We use Firebase for authentication and Crashlytics for error reporting.\n'
                '• Your data is securely stored, and you can request account deletion at any time from your profile page.'),
            const SizedBox(height: 24),
            _buildSectionHeader('6. Termination'),
            _buildParagraph(
                'We reserve the right to suspend or terminate your account without prior notice if you violate these terms. Any accumulated virtual currency or pending withdrawals will be voided upon termination.'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }
}
