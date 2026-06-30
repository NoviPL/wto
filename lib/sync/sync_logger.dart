import '../db/database.dart';

class SyncLogger {
  static Future<T> run<T>(
    String action,
    Future<T> Function() task,
  ) async {
    await AppDatabase.addSyncHistory(
      action: action,
      status: 'START',
      details: 'Rozpoczęto',
    );

    try {
      final result = await task();

      await AppDatabase.addSyncHistory(
        action: action,
        status: 'OK',
        details: 'Zakończono poprawnie',
      );

      return result;
    } catch (e) {
      await AppDatabase.addSyncHistory(
        action: action,
        status: 'BŁĄD',
        details: e.toString(),
      );

      rethrow;
    }
  }

  static Future<void> info(
    String action,
    String details,
  ) async {
    await AppDatabase.addSyncHistory(
      action: action,
      status: 'OK',
      details: details,
    );
  }

  static Future<void> error(
    String action,
    Object error,
  ) async {
    await AppDatabase.addSyncHistory(
      action: action,
      status: 'BŁĄD',
      details: error.toString(),
    );
  }
}