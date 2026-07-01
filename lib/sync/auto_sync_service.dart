import 'dart:async';

import 'sync_manager.dart';

class AutoSyncService {
  static Timer? _timer;
  static bool _isRunning = false;
  static bool _syncInProgress = false;

  static const Duration interval = Duration(seconds: 30);

  static void start() {
    if (_isRunning) return;

    _isRunning = true;

    _timer = Timer.periodic(interval, (_) {
      runOnce();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _syncInProgress = false;
  }

  static Future<void> runOnce() async {
    if (_syncInProgress) return;

    _syncInProgress = true;

    try {
      await SyncManager.syncAll();
    } catch (_) {
      // Celowo bez rzucania błędu.
      // Auto-sync nie może wywalić aplikacji.
    } finally {
      _syncInProgress = false;
    }
  }

  static bool get isRunning => _isRunning;
  static bool get syncInProgress => _syncInProgress;
}