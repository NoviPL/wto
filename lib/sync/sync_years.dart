import '../api/wto_api.dart';
import '../db/database.dart';

class SyncYears {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncYearsFromServer();
  }

  static Future<bool> sendYear({
    required int year,
  }) async {
    return WtoApi.sendYear(year: year);
  }

  static Future<bool> deleteYear({
    required int year,
  }) async {
    return WtoApi.deleteYear(year: year);
  }
}