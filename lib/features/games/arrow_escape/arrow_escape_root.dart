import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'arrow_escape_providers.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/level_repository.dart';
import 'screens/home/home_screen.dart';

class ArrowEscapeRootWidget extends StatefulWidget {
  const ArrowEscapeRootWidget({super.key});

  @override
  State<ArrowEscapeRootWidget> createState() => _ArrowEscapeRootWidgetState();
}

class _ArrowEscapeRootWidgetState extends State<ArrowEscapeRootWidget> {
  ProgressRepository? _progressRepo;
  LevelRepository? _levelRepo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      await Hive.initFlutter();
      _progressRepo = await ProgressRepository.create();
      _levelRepo = await LevelRepository.create();
    } catch (e) {
      debugPrint('Error initializing Hive in Arrow Escape: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _progressRepo == null || _levelRepo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWith((ref) => _progressRepo!),
        levelRepositoryProvider.overrideWithValue(_levelRepo!),
      ],
      child: const HomeScreen(),
    );
  }
}
