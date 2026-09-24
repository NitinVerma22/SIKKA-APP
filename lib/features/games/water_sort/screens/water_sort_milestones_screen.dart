import 'package:flutter/material.dart';
import '../../shared/screens/milestone_selection_screen.dart';
import '../services/water_sort_service.dart';

class WaterSortMilestonesScreen extends StatefulWidget {
  const WaterSortMilestonesScreen({super.key});

  @override
  State<WaterSortMilestonesScreen> createState() => _WaterSortMilestonesScreenState();
}

class _WaterSortMilestonesScreenState extends State<WaterSortMilestonesScreen> {
  final WaterSortService _service = WaterSortService();
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
      gameName: 'Color Sort',
      gameRoute: '/games/water_sort/level_select',
      globalMaxLevel: _maxUnlockedLevel,
      themeColor: const Color(0xFF257CE9),
    );
  }
}
