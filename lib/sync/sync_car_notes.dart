import '../api/wto_api.dart';
import '../db/database.dart';

class SyncCarNotes {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncCarNotesFromServer();
  }

  static Future<bool> sendCarNote({
    required String carNoteUuid,
    required String carUuid,
    required String section,
    required String text,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    return WtoApi.sendCarNote(
      carNoteUuid: carNoteUuid,
      carUuid: carUuid,
      section: section,
      text: text,
      dateTime: dateTime,
      userId: userId,
      serverImagePath: serverImagePath,
      deleted: deleted,
    );
  }
}