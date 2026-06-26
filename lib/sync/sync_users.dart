import '../api/wto_api.dart';
import '../db/database.dart';

class SyncUsers {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncUsersFromServer();
  }

  static Future<bool> sendUser({
    required String id,
    required String name,
    required String role,
    required String pin,
  }) async {
    return WtoApi.sendUser(
      id: id,
      name: name,
      role: role,
      pin: pin,
    );
  }

  static Future<bool> deleteUser(String id) async {
    return WtoApi.deleteUser(id);
  }
}