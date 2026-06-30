import '../api/wto_api.dart';
import '../db/database.dart';

class SyncMessageImages {
  static Future<void> syncFromServer() async {
    final images = await WtoApi.getMessageImages();

    for (final item in images) {
      await AppDatabase.upsertMessageImageFromServer(
        imageUuid: item['image_uuid']?.toString() ?? '',
        messageUuid: item['message_uuid']?.toString() ?? '',
        serverImagePath: item['imagePath']?.toString(),
        caption: item['caption']?.toString() ?? '',
        deleted: item['deleted'] == true ||
            item['deleted'] == 1 ||
            item['deleted']?.toString() == '1',
      );
    }
  }

  static Future<bool> sendMessageImage({
    required String imageUuid,
    required String messageUuid,
    String? serverImagePath,
    String caption = '',
    bool deleted = false,
  }) async {
    return WtoApi.sendMessageImage(
      imageUuid: imageUuid,
      messageUuid: messageUuid,
      serverImagePath: serverImagePath,
      caption: caption,
      deleted: deleted,
    );
  }
}