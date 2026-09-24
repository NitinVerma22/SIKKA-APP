import 'package:flutter/material.dart';
import '../../shared/screens/milestone_selection_screen.dart';
import '../services/bubble_shooter_service.dart';

class BubbleShooterMilestonesScreen extends StatefulWidget {
  const BubbleShooterMilestonesScreen({super.key});

  @override
  State<BubbleShooterMilestonesScreen> createState() => _BubbleShooterMilestonesScreenState();
}

class _BubbleShooterMilestonesScreenState extends State<BubbleShooterMilestonesScreen> {
  final BubbleShooterService _service = BubbleShooterService();
  bool _isLoading = true;
  int _maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _maxUnlockedLevel = progress.maxUnlockedLevel;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MilestoneSelectionScreen(
      gameName: 'Bubble Sort',
      gameRoute: '/games/bubble_shooter/level_select',
      globalMaxLevel: _maxUnlockedLevel,
      themeColor: const Color(0xFF21B761),
    );
  }
}
