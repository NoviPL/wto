import 'sync_users.dart';
import 'sync_years.dart';
import 'sync_tasks.dart';
import 'sync_entries.dart';

class SyncManager {
  static Future<void> syncAll() async {
    await syncUsersFromServer();
    await syncYearsFromServer();
    await syncTasksFromServer();
    await syncEntriesFromServer();
  }

  static Future<void> syncUsersFromServer() async {
    await SyncUsers.syncFromServer();
  }

  static Future<void> syncYearsFromServer() async {
    await SyncYears.syncFromServer();
  }

  static Future<void> syncTasksFromServer() async {
    await SyncTasks.syncFromServer();
  }

  static Future<bool> sendUser({
    required String id,
    required String name,
    required String role,
    required String pin,
  }) async {
    return SyncUsers.sendUser(
      id: id,
      name: name,
      role: role,
      pin: pin,
    );
  }

  static Future<bool> deleteUser(String id) async {
    return SyncUsers.deleteUser(id);
  }

  static Future<bool> sendYear({
    required int year,
  }) async {
    return SyncYears.sendYear(year: year);
  }

  static Future<bool> sendTask({
    required int year,
    required String number,
  }) async {
    return SyncTasks.sendTask(
      year: year,
      number: number,
    );
  }

  static Future<bool> deleteTask({
    required int year,
    required String number,
  }) async {
    return SyncTasks.deleteTask(
      year: year,
      number: number,
    );
  }
  static Future<void> syncEntriesFromServer() async {
    await SyncEntries.syncFromServer();
  }

  static Future<bool> sendEntry({
    required String entryUuid,
    required String number,
    required String category,
    required String text,
    required String dateTime,
    required String userId,
    String? imagePath,
    bool deleted = false,
  }) async {
    return SyncEntries.sendEntry(
      entryUuid: entryUuid,
      number: number,
      category: category,
      text: text,
      dateTime: dateTime,
      imagePath: imagePath,
      userId: userId,
      deleted: deleted,
    );
  }
}