import 'sync_users.dart';

class SyncManager {
  static Future<void> syncAll() async {
    await syncUsersFromServer();
  }

  static Future<void> syncUsersFromServer() async {
    await SyncUsers.syncFromServer();
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
}