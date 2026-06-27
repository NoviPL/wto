import '../api/wto_api.dart';
import '../db/database.dart';

class SyncTasks {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncTasksFromServer();
  }

  static Future<bool> sendTask({
    required int year,
    required String number,
  }) async {
    return WtoApi.sendTask(
      year: year,
      number: number,
    );
  }

  static Future<bool> deleteTask({
    required int year,
    required String number,
  }) async {
    return WtoApi.deleteTask(
      year: year,
      number: number,
    );
  }
}