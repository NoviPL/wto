import '../api/wto_api.dart';
import '../db/database.dart';

class SyncEntries {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncEntriesFromServer();
  }

  static Future<bool> sendEntry({
    required String entryUuid,
    required String number,
    required String category,
    required String text,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    return WtoApi.sendEntry(
      entryUuid: entryUuid,
      number: number,
      category: category,
      text: text,
      dateTime: dateTime,
      serverImagePath: serverImagePath,
      userId: userId,
      deleted: deleted,
    );
  }
}