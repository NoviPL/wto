class SyncQueue {
  static Future<bool> run(
    Future<bool> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return false;
    }
  }

  static Future<void> runVoid(
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {}
  }
}