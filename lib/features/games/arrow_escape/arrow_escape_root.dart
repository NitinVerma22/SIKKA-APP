import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/repositories/progress_repository.dart';
import 'data/repositories/level_repository.dart';
import 'screens/home/home_screen.dart';
import 'main.dart';

class ArrowEscapeRootWidget extends StatefulWidget {
  const ArrowEscapeRootWidget({super.key});

  @override
  State<ArrowEscapeRootWidget> createState() => _ArrowEscapeRootWidgetState();
}

class _ArrowEscapeRootWidgetState extends State<ArrowEscapeRootWidget> {
  ProgressRepository? _progressRepo;
  LevelRepository? _levelRepo;
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initHiveAndRepos();
  }

  Future<void> _initHiveAndRepos() async {
    try {
      await Hive.initFlutter();

      final progressRepo = await ProgressRepository.create();
      final levelRepo = await LevelRepository.create();

      if (mounted) {
        setState(() {
          _progressRepo = progressRepo;
          _levelRepo = levelRepo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF38BDF8)),
              SizedBox(height: 16),
              Text(
                'Loading Arrow Escape...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMsg != null || _progressRepo == null || _levelRepo == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize Arrow Escape:\n$_errorMsg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMsg = null;
                    });
                    _initHiveAndRepos();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
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
