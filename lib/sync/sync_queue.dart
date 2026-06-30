import 'dart:convert';

import '../db/database.dart';

class SyncQueue {
  static Future<bool> run(
    Future<bool> Function() action, {
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    final ok = await action();

    if (ok) return true;

    if (type != null && payload != null) {
      await AppDatabase.addSyncQueueItem(
        type: type,
        payload: payload,
      );
    }

    return false;
  }

  static Future<void> processPending() async {
    final items = await AppDatabase.getSyncQueueItems();

    for (final item in items) {
      final id = item['id'] as int;
      final type = item['type']?.toString() ?? '';
      final payloadText = item['payload']?.toString() ?? '{}';

      try {
        final payload = jsonDecode(payloadText) as Map<String, dynamic>;

        final ok = await AppDatabase.processSyncQueueItem(
          type: type,
          payload: payload,
        );

        if (ok) {
          await AppDatabase.deleteSyncQueueItem(id);
        } else {
          await AppDatabase.markSyncQueueItemFailed(
            id,
            'Serwer odrzucił operację',
          );
        }
      } catch (e) {
        await AppDatabase.markSyncQueueItemFailed(
          id,
          e.toString(),
        );
      }
    }
  }
}