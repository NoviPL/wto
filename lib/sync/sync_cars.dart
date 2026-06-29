import '../api/wto_api.dart';
import '../db/database.dart';

class SyncCars {
  static Future<void> syncFromServer() async {
    await AppDatabase.syncCarsFromServer();
  }

  static Future<bool> sendCar({
    required String carUuid,
    required String name,
    required String plate,
    required String createdAt,
    required int colorIndex,
    bool deleted = false,
  }) async {
    return WtoApi.sendCar(
      carUuid: carUuid,
      name: name,
      plate: plate,
      createdAt: createdAt,
      colorIndex: colorIndex,
      deleted: deleted,
    );
  }
}