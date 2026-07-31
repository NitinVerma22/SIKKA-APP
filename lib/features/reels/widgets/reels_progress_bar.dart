import 'package:flutter/material.dart';

/// Earnings progress removed for clean UX.
/// Kept as an empty widget to avoid touching the reels layout structure.
class ReelsProgressBar extends StatelessWidget {
  const ReelsProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
