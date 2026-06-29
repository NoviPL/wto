import '../api/wto_api.dart';
import '../db/database.dart';

class SyncMessages {
  static Future<void> syncFromServer() async {
    final messages = await WtoApi.getMessages();

    for (final item in messages) {
      await AppDatabase.upsertMessageFromServer(
        messageUuid: item['message_uuid']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        text: item['text']?.toString() ?? '',
        level: item['level']?.toString() ?? 'OGŁOSZENIE',
        dateTime: item['dateTime']?.toString() ?? '',
        userId: item['userId']?.toString() ?? 'USER_001',
        serverImagePath: item['imagePath']?.toString(),
        deleted: item['deleted'] == true ||
            item['deleted'] == 1 ||
            item['deleted']?.toString() == '1',
      );
    }

    final reads = await WtoApi.getMessageReads();

    for (final item in reads) {
      await AppDatabase.upsertMessageReadFromServer(
        messageUuid: item['message_uuid']?.toString() ?? '',
        userId: item['userId']?.toString() ?? '',
        readAt: item['readAt']?.toString() ?? '',
      );
    }
  }

  static Future<bool> sendMessage({
    required String messageUuid,
    required String title,
    required String text,
    required String level,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    return WtoApi.sendMessage(
      messageUuid: messageUuid,
      title: title,
      text: text,
      level: level,
      dateTime: dateTime,
      userId: userId,
      serverImagePath: serverImagePath,
      deleted: deleted,
    );
  }

  static Future<bool> markMessageRead({
    required String messageUuid,
    required String userId,
    required String readAt,
  }) async {
    return WtoApi.markMessageRead(
      messageUuid: messageUuid,
      userId: userId,
      readAt: readAt,
    );
  }
}