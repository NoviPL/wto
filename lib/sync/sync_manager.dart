import 'sync_users.dart';
import 'sync_years.dart';
import 'sync_tasks.dart';
import 'sync_entries.dart';
import 'sync_queue.dart';
import 'sync_cars.dart';
import 'sync_car_terms.dart';
import 'sync_car_notes.dart';
import 'sync_messages.dart';
import 'sync_message_images.dart';

class SyncManager {
  static Future<void> syncAll() async {
    await SyncQueue.processPending();

    await syncUsersFromServer();
    await syncYearsFromServer();
    await syncTasksFromServer();
    await syncEntriesFromServer();
    await syncCarsFromServer();
    await syncCarTermsFromServer();
    await syncCarNotesFromServer();
    await syncMessagesFromServer();
    await syncMessageImagesFromServer();
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

  static Future<void> syncEntriesFromServer() async {
    await SyncQueue.processPending();
    await SyncEntries.syncFromServer();
  }

  static Future<void> syncCarsFromServer() async {
    await SyncQueue.processPending();
    await SyncCars.syncFromServer();
  }

  static Future<void> syncCarTermsFromServer() async {
    await SyncCarTerms.syncFromServer();
  }

  static Future<void> syncCarNotesFromServer() async {
    await SyncQueue.processPending();
    await SyncCarNotes.syncFromServer();
  }

  static Future<void> syncMessagesFromServer() async {
    await SyncQueue.processPending();
    await SyncMessages.syncFromServer();
  }

  static Future<void> syncMessageImagesFromServer() async {
    await SyncQueue.processPending();
    await SyncMessageImages.syncFromServer();
  }

  static Future<bool> sendUser({
    required String id,
    required String name,
    required String role,
    required String pin,
  }) async {
    return SyncQueue.run(() {
      return SyncUsers.sendUser(
        id: id,
        name: name,
        role: role,
        pin: pin,
      );
    }, type: 'user', payload: {
      'id': id,
      'name': name,
      'role': role,
      'pin': pin,
    });
  }

  static Future<bool> deleteUser(String id) async {
    return SyncQueue.run(() {
      return SyncUsers.deleteUser(id);
    }, type: 'delete_user', payload: {
      'id': id,
    });
  }

  static Future<bool> sendYear({
    required int year,
  }) async {
    return SyncQueue.run(() {
      return SyncYears.sendYear(year: year);
    }, type: 'year', payload: {
      'year': year,
    });
  }

  static Future<bool> deleteYear({
    required int year,
  }) async {
    return SyncQueue.run(() {
      return SyncYears.deleteYear(year: year);
    }, type: 'delete_year', payload: {
      'year': year,
    });
  }

  static Future<bool> sendTask({
    required int year,
    required String number,
  }) async {
    return SyncQueue.run(() {
      return SyncTasks.sendTask(
        year: year,
        number: number,
      );
    }, type: 'task', payload: {
      'year': year,
      'number': number,
    });
  }

  static Future<bool> deleteTask({
    required int year,
    required String number,
  }) async {
    return SyncQueue.run(() {
      return SyncTasks.deleteTask(
        year: year,
        number: number,
      );
    }, type: 'delete_task', payload: {
      'year': year,
      'number': number,
    });
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
    return SyncQueue.run(() {
      return SyncEntries.sendEntry(
        entryUuid: entryUuid,
        number: number,
        category: category,
        text: text,
        dateTime: dateTime,
        serverImagePath: serverImagePath,
        userId: userId,
        deleted: deleted,
      );
    }, type: 'entry', payload: {
      'entryUuid': entryUuid,
      'number': number,
      'category': category,
      'text': text,
      'dateTime': dateTime,
      'userId': userId,
      'serverImagePath': serverImagePath,
      'deleted': deleted,
    });
  }

  static Future<bool> sendCar({
    required String carUuid,
    required String name,
    required String plate,
    required String createdAt,
    required int colorIndex,
    bool deleted = false,
  }) async {
    return SyncQueue.run(() {
      return SyncCars.sendCar(
        carUuid: carUuid,
        name: name,
        plate: plate,
        createdAt: createdAt,
        colorIndex: colorIndex,
        deleted: deleted,
      );
    }, type: 'car', payload: {
      'carUuid': carUuid,
      'name': name,
      'plate': plate,
      'createdAt': createdAt,
      'colorIndex': colorIndex,
      'deleted': deleted,
    });
  }

  static Future<bool> sendCarTerms({
    required String carUuid,
    String? ocDate,
    String? acDate,
    String? btDate,
    bool deleted = false,
  }) async {
    return SyncQueue.run(() {
      return SyncCarTerms.sendCarTerms(
        carUuid: carUuid,
        ocDate: ocDate,
        acDate: acDate,
        btDate: btDate,
        deleted: deleted,
      );
    }, type: 'car_terms', payload: {
      'carUuid': carUuid,
      'ocDate': ocDate,
      'acDate': acDate,
      'btDate': btDate,
      'deleted': deleted,
    });
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
    return SyncQueue.run(() {
      return SyncCarNotes.sendCarNote(
        carNoteUuid: carNoteUuid,
        carUuid: carUuid,
        section: section,
        text: text,
        dateTime: dateTime,
        userId: userId,
        serverImagePath: serverImagePath,
        deleted: deleted,
      );
    }, type: 'car_note', payload: {
      'carNoteUuid': carNoteUuid,
      'carUuid': carUuid,
      'section': section,
      'text': text,
      'dateTime': dateTime,
      'userId': userId,
      'serverImagePath': serverImagePath,
      'deleted': deleted,
    });
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
    return SyncQueue.run(() {
      return SyncMessages.sendMessage(
        messageUuid: messageUuid,
        title: title,
        text: text,
        level: level,
        dateTime: dateTime,
        userId: userId,
        serverImagePath: serverImagePath,
        deleted: deleted,
      );
    }, type: 'message', payload: {
      'messageUuid': messageUuid,
      'title': title,
      'text': text,
      'level': level,
      'dateTime': dateTime,
      'userId': userId,
      'serverImagePath': serverImagePath,
      'deleted': deleted,
    });
  }

  static Future<bool> markMessageRead({
    required String messageUuid,
    required String userId,
    required String readAt,
  }) async {
    return SyncQueue.run(() {
      return SyncMessages.markMessageRead(
        messageUuid: messageUuid,
        userId: userId,
        readAt: readAt,
      );
    }, type: 'message_read', payload: {
      'messageUuid': messageUuid,
      'userId': userId,
      'readAt': readAt,
    });
  }

  static Future<bool> sendMessageImage({
    required String imageUuid,
    required String messageUuid,
    String? serverImagePath,
    String caption = '',
    bool deleted = false,
  }) async {
    return SyncQueue.run(() {
      return SyncMessageImages.sendMessageImage(
        imageUuid: imageUuid,
        messageUuid: messageUuid,
        serverImagePath: serverImagePath,
        caption: caption,
        deleted: deleted,
      );
    }, type: 'message_image', payload: {
      'imageUuid': imageUuid,
      'messageUuid': messageUuid,
      'serverImagePath': serverImagePath,
      'caption': caption,
      'deleted': deleted,
    });
  }
}