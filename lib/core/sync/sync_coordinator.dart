import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/wallet/controllers/wallet_controller.dart';
import 'package:sikkaplay/features/rewards/controllers/network_controller.dart';

enum SyncEvent {
  balanceChanged,
  profileUpdated,
  tasksUpdated,
  networkUpdated,
}

class SyncCoordinator {
  final Ref _ref;
  final List<SyncEvent> _eventQueue = [];
  Timer? _debounceTimer;
  bool _isProcessing = false;

  SyncCoordinator(this._ref);

  /// Triggers synchronization for a list of events.
  /// Events are queued and debounced (300ms) to prevent duplicate API requests.
  void triggerSync(List<SyncEvent> events) {
    _eventQueue.addAll(events);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _processQueue();
    });
  }

  /// Processes the queued events, resolves affected providers, and executes refreshes.
  Future<void> _processQueue() async {
    if (_isProcessing || _eventQueue.isEmpty) return;
    _isProcessing = true;

    // Extract unique events and clear the queue
    final uniqueEvents = _eventQueue.toSet().toList();
    _eventQueue.clear();

    if (kDebugMode) {
      print('[SYNC COORDINATOR] Processing events: $uniqueEvents');
    }

    // Determine affected providers
    final refreshProfile = uniqueEvents.contains(SyncEvent.balanceChanged) ||
        uniqueEvents.contains(SyncEvent.profileUpdated) ||
        uniqueEvents.contains(SyncEvent.networkUpdated);

    final refreshHome = uniqueEvents.contains(SyncEvent.balanceChanged) ||
        uniqueEvents.contains(SyncEvent.profileUpdated) ||
        uniqueEvents.contains(SyncEvent.tasksUpdated);

    final refreshWallet = uniqueEvents.contains(SyncEvent.balanceChanged);

    final refreshNetwork = uniqueEvents.contains(SyncEvent.networkUpdated);

    final List<Future<void>> refreshTasks = [];

    if (refreshProfile) {
      refreshTasks.add(_retryOperation(() async {
        await _ref.read(userProvider.notifier).fetchProfile(silent: true);
      }, 'Profile'));
    }

    if (refreshHome) {
      refreshTasks.add(_retryOperation(() async {
        await _ref.read(homeProvider.notifier).refresh(silent: true);
      }, 'HomeState'));
    }

    if (refreshWallet) {
      refreshTasks.add(_retryOperation(() async {
        await _ref.read(walletProvider.notifier).fetchWalletData();
      }, 'Wallet'));
    }

    if (refreshNetwork) {
      refreshTasks.add(_retryOperation(() async {
        await _ref.read(networkProvider.notifier).fetchNetwork();
      }, 'Network'));
    }

    try {
      await Future.wait(refreshTasks);
    } catch (e) {
      if (kDebugMode) {
        print('[SYNC COORDINATOR] Batch sync completed with some errors: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Executes an operation with up to 3 attempts using exponential backoff.
  Future<void> _retryOperation(Future<void> Function() operation, String name) async {
    int attempts = 0;
    int delayMs = 1000;
    while (attempts < 3) {
      try {
        await operation();
        return; // Success
      } catch (e) {
        attempts++;
        if (kDebugMode) {
          print('[SYNC COORDINATOR] $name refresh failed (Attempt $attempts/3): $e');
        }
        if (attempts >= 3) {
          break;
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // Exponential backoff (1s -> 2s)
      }
    }
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(ref);
});
