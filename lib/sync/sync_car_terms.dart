import '../api/wto_api.dart';
import '../db/database.dart';

class SyncCarTerms {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncCarTermsFromServer();
  }

  static Future<bool> sendCarTerms({
    required String carUuid,
    String? ocDate,
    String? acDate,
    String? btDate,
    bool deleted = false,
  }) async {
    return WtoApi.sendCarTerms(
      carUuid: carUuid,
      ocDate: ocDate,
      acDate: acDate,
      btDate: btDate,
      deleted: deleted,
    );
  }
}