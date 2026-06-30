import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import '../api/wto_api.dart';
import '../sync/sync_manager.dart';
import 'package:uuid/uuid.dart';
import '../sync/upload_manager.dart';
import '../sync/download_manager.dart';

class AppDatabase {
  static Database? _db;

  static Future<Map<String, int>> getCarSectionCounts(int carId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT section, COUNT(*) as count
      FROM car_notes
      WHERE carId = ?
      GROUP BY section
    ''', [carId]);

    final counts = <String, int>{};

    for (final row in result) {
      counts[row['section'].toString()] = row['count'] as int;
    }

    return counts;
  }

  static Future<Map<String, dynamic>?> getCarTerms(int carId) async {
    final db = await database;

    final result = await db.query(
      'car_terms',
      where: 'carId = ?',
      whereArgs: [carId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  static Future<void> saveCarTerms(
    int carId,
    String? ocDate,
    String? acDate,
    String? btDate,
  ) async {
    final db = await database;

    final existing = await getCarTerms(carId);

    final oldValue = existing == null
        ? ''
        : 'OC: ${existing['ocDate'] ?? '-'} | AC: ${existing['acDate'] ?? '-'} | BT: ${existing['btDate'] ?? '-'}';

    final newValue =
        'OC: ${ocDate ?? '-'} | AC: ${acDate ?? '-'} | BT: ${btDate ?? '-'}';

    if (existing == null) {
      await db.insert('car_terms', {
        'carId': carId,
        'ocDate': ocDate,
        'acDate': acDate,
        'btDate': btDate,
      });
    } else {
      await db.update(
        'car_terms',
        {
          'ocDate': ocDate,
          'acDate': acDate,
          'btDate': btDate,
        },
        where: 'carId = ?',
        whereArgs: [carId],
      );
    }

    await addChangeLog(
      entityType: 'OC/AC/BT',
      entityId: carId.toString(),
      action: existing == null ? 'Dodanie' : 'Edycja',
      oldValue: oldValue,
      newValue: newValue,
    );
    final car = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [carId],
      limit: 1,
    );

    if (car.isNotEmpty) {
      final carUuid = car.first['car_uuid']?.toString();

      if (carUuid != null && carUuid.isNotEmpty) {
        await SyncManager.sendCarTerms(
          carUuid: carUuid,
          ocDate: ocDate,
          acDate: acDate,
          btDate: btDate,
        );
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getCars() async {
    final db = await database;

    return db.query(
      'cars',
      orderBy: 'id DESC',
    );
  }

  static Future<void> insertCar(
    String name,
    String plate,
    String createdAt,
    int colorIndex,
  ) async {
    final db = await database;
    final carUuid = const Uuid().v4();

    final id = await db.insert('cars', {
      'car_uuid': carUuid,
      'name': name,
      'plate': plate,
      'createdAt': createdAt,
      'colorIndex': colorIndex,
    });

    await addChangeLog(
      entityType: 'Auto',
      entityId: id.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: '$name | $plate',
    );
    await SyncManager.sendCar(
      carUuid: carUuid,
      name: name,
      plate: plate,
      createdAt: createdAt,
      colorIndex: colorIndex,
    );
  }

  static Future<void> updateCar(
    int id,
    String name,
    String plate,
  ) async {
    final db = await database;

    final old = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty
        ? ''
        : '${old.first['name']} | ${old.first['plate']}';

    final newValue = '$name | $plate';

    await db.update(
      'cars',
      {
        'name': name,
        'plate': plate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (old.isNotEmpty) {
      final car = old.first;
      final carUuid = car['car_uuid']?.toString();

      if (carUuid != null && carUuid.isNotEmpty) {
        await SyncManager.sendCar(
          carUuid: carUuid,
          name: name,
          plate: plate,
          createdAt: car['createdAt']?.toString() ?? '',
          colorIndex:
              int.tryParse(car['colorIndex']?.toString() ?? '0') ?? 0,
        );
      }
    }

    await addChangeLog(
      entityType: 'Auto',
      entityId: id.toString(),
      action: 'Edycja',
      oldValue: oldValue,
      newValue: newValue,
    );
  }
  static Future<void> deleteCar(int id) async {
    final db = await database;

    final old = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty
        ? ''
        : '${old.first['name']} | ${old.first['plate']}';

    if (old.isNotEmpty) {
      final car = old.first;
      final carUuid = car['car_uuid']?.toString();

      if (carUuid != null && carUuid.isNotEmpty) {
        await SyncManager.sendCar(
          carUuid: carUuid,
          name: car['name']?.toString() ?? '',
          plate: car['plate']?.toString() ?? '',
          createdAt: car['createdAt']?.toString() ?? '',
          colorIndex:
              int.tryParse(car['colorIndex']?.toString() ?? '0') ?? 0,
          deleted: true,
        );
      }
    }

    await db.delete(
      'car_notes',
      where: 'carId = ?',
      whereArgs: [id],
    );

    await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );

    await addChangeLog(
      entityType: 'Auto',
      entityId: id.toString(),
      action: 'Usunięcie',
      oldValue: oldValue,
      newValue: '',
    );
  }

  static Future<List<Map<String, dynamic>>> getCarNotes(
    int carId,
    String section,
  ) async {
    final db = await database;

    return db.query(
      'car_notes',
      where: 'carId = ? AND section = ?',
      whereArgs: [carId, section],
      orderBy: 'id DESC',
    );
  }

  static Future<void> insertCarNote(
    int carId,
    String section,
    String text,
    String dateTime,
    String userId, {
    String? imagePath,
  }) async {
    final db = await database;
    final carNoteUuid = const Uuid().v4();

    String? serverImagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      serverImagePath = await UploadManager.uploadFile(imagePath);
    }

    final id = await db.insert('car_notes', {
      'car_note_uuid': carNoteUuid,
      'carId': carId,
      'section': section,
      'text': text,
      'dateTime': dateTime,
      'userId': userId,
      'imagePath': imagePath,
      'serverImagePath': serverImagePath,
    });

    await addChangeLog(
      entityType: imagePath == null || imagePath.isEmpty
          ? 'Flota / notatka'
          : 'Flota / zdjęcie',
      entityId: id.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: '$section | $text',
    );
    final car = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [carId],
      limit: 1,
    );

    if (car.isNotEmpty) {
      final carUuid = car.first['car_uuid']?.toString();

      if (carUuid != null && carUuid.isNotEmpty) {
        await SyncManager.sendCarNote(
          carNoteUuid: carNoteUuid,
          carUuid: carUuid,
          section: section,
          text: text,
          dateTime: dateTime,
          userId: userId,
          serverImagePath: serverImagePath,
        );
      }
    }
  }

  static Future<void> updateCarNote(
    int id,
    String text,
  ) async {
    final db = await database;

    final old = await db.query(
      'car_notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty ? '' : old.first['text']?.toString() ?? '';

    await db.update(
      'car_notes',
      {
        'text': text,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (old.isNotEmpty) {
      final note = old.first;

      final carId = note['carId'] as int;

      final car = await db.query(
        'cars',
        where: 'id = ?',
        whereArgs: [carId],
        limit: 1,
      );

      if (car.isNotEmpty) {
        final carUuid = car.first['car_uuid']?.toString();
        final carNoteUuid = note['car_note_uuid']?.toString();

        if (carUuid != null &&
            carUuid.isNotEmpty &&
            carNoteUuid != null &&
            carNoteUuid.isNotEmpty) {
          await SyncManager.sendCarNote(
            carNoteUuid: carNoteUuid,
            carUuid: carUuid,
            section: note['section']?.toString() ?? '',
            text: text,
            dateTime: note['dateTime']?.toString() ?? '',
            userId: note['userId']?.toString() ?? 'USER_001',
            serverImagePath: note['serverImagePath']?.toString(),
          );
        }
      }
    }

    await addChangeLog(
      entityType: 'Flota / notatka',
      entityId: id.toString(),
      action: 'Edycja',
      oldValue: oldValue,
      newValue: text,
    );
  }

  static Future<void> deleteCarNote(int id) async {
    final db = await database;

    final old = await db.query(
      'car_notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty
        ? ''
        : '${old.first['section']} | ${old.first['text']}';

    if (old.isNotEmpty) {
      final note = old.first;

      final carId = note['carId'] as int;

      final car = await db.query(
        'cars',
        where: 'id = ?',
        whereArgs: [carId],
        limit: 1,
      );

      if (car.isNotEmpty) {
        final carUuid = car.first['car_uuid']?.toString();
        final carNoteUuid = note['car_note_uuid']?.toString();

        if (carUuid != null &&
            carUuid.isNotEmpty &&
            carNoteUuid != null &&
            carNoteUuid.isNotEmpty) {
          await SyncManager.sendCarNote(
            carNoteUuid: carNoteUuid,
            carUuid: carUuid,
            section: note['section']?.toString() ?? '',
            text: note['text']?.toString() ?? '',
            dateTime: note['dateTime']?.toString() ?? '',
            userId: note['userId']?.toString() ?? 'USER_001',
            serverImagePath: note['serverImagePath']?.toString(),
            deleted: true,
          );
        }
      }
    }
    await db.delete(
      'car_notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    await addChangeLog(
      entityType: 'Flota / notatka',
      entityId: id.toString(),
      action: 'Usunięcie',
      oldValue: oldValue,
      newValue: '',
    );
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB();
    return _db!;
  }

  static Future<int> getEntriesCount(String number) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM entries WHERE number = ?',
      [number],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wto.db');

    return openDatabase(
      path,
      version: 21,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_uuid TEXT UNIQUE,
            number TEXT,
            category TEXT,
            text TEXT,
            dateTime TEXT,
            imagePath TEXT,
            serverImagePath TEXT,
            userId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER,
            number TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE years (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE cars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            car_uuid TEXT UNIQUE,
            name TEXT NOT NULL,
            plate TEXT,
            createdAt TEXT,
            colorIndex INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE car_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            car_note_uuid TEXT UNIQUE,
            carId INTEGER NOT NULL,
            section TEXT NOT NULL,
            text TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            userId TEXT NOT NULL,
            imagePath TEXT,
            serverImagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE car_terms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            carId INTEGER NOT NULL UNIQUE,
            ocDate TEXT,
            acDate TEXT,
            btDate TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message_uuid TEXT UNIQUE,
            title TEXT NOT NULL,
            text TEXT NOT NULL,
            level TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            userId TEXT NOT NULL,
            imagePath TEXT,
            serverImagePath TEXT,
            deleted INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE message_reads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message_uuid TEXT NOT NULL,
            userId TEXT NOT NULL,
            readAt TEXT NOT NULL,
            UNIQUE(message_uuid, userId)
          )
        ''');

        await db.execute('''
          CREATE TABLE message_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_uuid TEXT UNIQUE,
            message_uuid TEXT NOT NULL,
            imagePath TEXT,
            serverImagePath TEXT,
            caption TEXT,
            deleted INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            isAdmin INTEGER DEFAULT 0,
            role TEXT DEFAULT 'USER',
            pin TEXT DEFAULT '0000'
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE change_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entityType TEXT NOT NULL,
            entityId TEXT NOT NULL,
            action TEXT NOT NULL,
            oldValue TEXT,
            newValue TEXT,
            userId TEXT NOT NULL,
            userName TEXT NOT NULL,
            dateTime TEXT NOT NULL
          )
        ''');

        await db.insert(
          'users', 
          {
          'id': 'USER_001',
          'name': 'Użytkownik 1',
          'isAdmin': 1,
          'role': 'ADMIN',
          'pin': '0000',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        await db.insert('app_settings', {
          'key': 'currentUserId',
          'value': 'USER_001',
        });

        await db.insert('years', {'year': 2025});
        await db.insert('years', {'year': 2026});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE entries ADD COLUMN imagePath TEXT');
          } catch (_) {}
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              year INTEGER,
              number TEXT
            )
          ''');
        }

        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE entries ADD COLUMN category TEXT');
          } catch (_) {}
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS years (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              year INTEGER UNIQUE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS cars (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              plate TEXT,
              createdAt TEXT,
              colorIndex INTEGER DEFAULT 0
            )
          ''');

          await db.insert(
            'years',
            {'year': 2025},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          await db.insert(
            'years',
            {'year': 2026},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS car_notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              carId INTEGER NOT NULL,
              section TEXT NOT NULL,
              text TEXT NOT NULL,
              dateTime TEXT NOT NULL,
              userId TEXT NOT NULL,
              imagePath TEXT
            )
          ''');

          try {
            await db.execute(
              'ALTER TABLE cars ADD COLUMN colorIndex INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }

        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE car_notes ADD COLUMN imagePath TEXT');
          } catch (_) {}

          await db.execute('''
            CREATE TABLE IF NOT EXISTS car_terms (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              carId INTEGER NOT NULL UNIQUE,
              ocDate TEXT,
              acDate TEXT,
              btDate TEXT
            )
          ''');
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              text TEXT NOT NULL,
              level TEXT NOT NULL,
              dateTime TEXT NOT NULL,
              userId TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 9) {
          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN isRead INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 10) {
          try {
            await db.execute(
              'ALTER TABLE entries ADD COLUMN userId TEXT DEFAULT "USER_001"',
            );
          } catch (_) {}
        }
        if (oldVersion < 11) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_settings (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');

          await db.insert(
            'users',
            {
              'id': 'USER_001',
              'name': 'Użytkownik 1',
              'pin': '0000'
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          await db.insert(
            'app_settings',
            {
              'key': 'currentUserId',
              'value': 'USER_001',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        if (oldVersion < 12) {
          try {
            await db.execute(
              'ALTER TABLE users ADD COLUMN isAdmin INTEGER DEFAULT 0',
            );
          } catch (_) {}

          await db.update(
            'users',
            {'isAdmin': 1},
            where: 'id = ?',
            whereArgs: ['USER_001'],
          );
        }
        if (oldVersion < 13) {
          try {
            await db.execute(
              'ALTER TABLE users ADD COLUMN pin TEXT DEFAULT "0000"',
            );
          } catch (_) {}
        }
        if (oldVersion < 14) {
          try {
            await db.execute(
              'ALTER TABLE users ADD COLUMN role TEXT DEFAULT "USER"',
            );
          } catch (_) {}

          await db.update(
            'users',
            {
              'role': 'ADMIN',
              'isAdmin': 1,
            },
            where: 'id = ?',
            whereArgs: ['USER_001'],
          );
        }
        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS change_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entityType TEXT NOT NULL,
              entityId TEXT NOT NULL,
              action TEXT NOT NULL,
              oldValue TEXT,
              newValue TEXT,
              userId TEXT NOT NULL,
              userName TEXT NOT NULL,
              dateTime TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 16) {
          try {
            await db.execute(
              'ALTER TABLE entries ADD COLUMN entry_uuid TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 17) {
          try {
            await db.execute(
              'ALTER TABLE entries ADD COLUMN serverImagePath TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 18) {
          try {
            await db.execute(
              'ALTER TABLE cars ADD COLUMN car_uuid TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 19) {
          try {
            await db.execute(
              'ALTER TABLE car_notes ADD COLUMN car_note_uuid TEXT',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE car_notes ADD COLUMN serverImagePath TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 20) {
          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN message_uuid TEXT',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN imagePath TEXT',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN serverImagePath TEXT',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN deleted INTEGER DEFAULT 0',
            );
          } catch (_) {}

          await db.execute('''
            CREATE TABLE IF NOT EXISTS message_reads (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              message_uuid TEXT NOT NULL,
              userId TEXT NOT NULL,
              readAt TEXT NOT NULL,
              UNIQUE(message_uuid, userId)
            )
          ''');
        }
        if (oldVersion < 21) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS message_images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image_uuid TEXT UNIQUE,
              message_uuid TEXT NOT NULL,
              imagePath TEXT,
              serverImagePath TEXT,
              caption TEXT,
              deleted INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  static Future<void> insertEntry(
    String number,
    String category,
    String text,
    String dateTime,
    String? imagePath,
    String userId,
  ) async {
    final db = await database;
    final entryUuid = const Uuid().v4();
    String? serverImagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      serverImagePath = await UploadManager.uploadFile(imagePath);
    }
    final id = await db.insert('entries', {
      'entry_uuid': entryUuid,
      'number': number,
      'category': category,
      'text': text,
      'dateTime': dateTime,
      'imagePath': imagePath,
      'serverImagePath': serverImagePath,
      'userId': userId,
    });

    await addChangeLog(
      entityType: imagePath == null || imagePath.isEmpty
          ? 'Wpis zadania'
          : 'Zdjęcie zadania',
      entityId: id.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: '$number | $category | $text',
    );
    await SyncManager.sendEntry(
      entryUuid: entryUuid,
      number: number,
      category: category,
      text: text,
      dateTime: dateTime,
      serverImagePath: serverImagePath,
      userId: userId,
    );
  }
  static Future<String?> getLastImagePath(String number) async {
    final db = await database;

    final result = await db.query(
      'entries',
      columns: ['imagePath'],
      where: 'number = ? AND imagePath IS NOT NULL AND imagePath != ""',
      whereArgs: [number],
     orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['imagePath'] as String?;
}
  static Future<List<Map<String, dynamic>>> getEntries(String number) async {
    final db = await database;

    return db.query(
      'entries',
      where: 'number = ?',
      whereArgs: [number],
      orderBy: 'CASE WHEN imagePath IS NOT NULL AND imagePath != "" THEN 0 ELSE 1 END, id ASC',
    );
  }
  static Future<void> deleteEntry(int id) async {
    final db = await database;

    final old = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (old.isEmpty) return;

    final entry = old.first;

    final entryUuid = entry['entry_uuid']?.toString();

    if (entryUuid != null && entryUuid.isNotEmpty) {
      await SyncManager.sendEntry(
        entryUuid: entryUuid,
        number: entry['number']?.toString() ?? '',
        category: entry['category']?.toString() ?? 'WPIS',
        text: entry['text']?.toString() ?? '',
        dateTime: entry['dateTime']?.toString() ?? '',
        serverImagePath: entry['serverImagePath']?.toString(),
        userId: entry['userId']?.toString() ?? 'USER_001',
        deleted: true,
      );
    }

    final oldValue =
        '${entry['number']} | ${entry['category']} | ${entry['text']}';

    await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    await addChangeLog(
      entityType: 'Zadanie / wpis',
      entityId: id.toString(),
      action: 'Usunięcie',
      oldValue: oldValue,
      newValue: '',
    );
  }

  static Future<void> updateEntryText(
    int id,
    String text,
  ) async {
    final db = await database;

    final old = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty ? '' : old.first['text']?.toString() ?? '';

    await db.update(
      'entries',
      {
        'text': text,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await addChangeLog(
      entityType: 'Wpis zadania',
      entityId: id.toString(),
      action: 'Edycja',
      oldValue: oldValue,
      newValue: text,
    );
    if (old.isNotEmpty) {
      final entry = old.first;

      final entryUuid = entry['entry_uuid']?.toString();

      if (entryUuid != null && entryUuid.isNotEmpty) {
        await SyncManager.sendEntry(
          entryUuid: entryUuid,
          number: entry['number']?.toString() ?? '',
          category: entry['category']?.toString() ?? 'WPIS',
          text: text,
          dateTime: entry['dateTime']?.toString() ?? '',
          serverImagePath: entry['serverImagePath']?.toString(),
          userId: entry['userId']?.toString() ?? 'USER_001',
        );
      }
    }
  }

  static Future<void> insertTask(int year, String number) async {
    final db = await database;

    final id = await db.insert('tasks', {
      'year': year,
      'number': number,
    });

    await addChangeLog(
      entityType: 'Zadanie',
      entityId: id.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: '$number | $year',
    );
    await SyncManager.sendTask(
      year: year,
      number: number,
    );
  }

  static Future<List<Map<String, dynamic>>> getTasks(int year) async {
    final db = await database;

    return db.query(
      'tasks',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'id DESC',
    );
  }
  static Future<void> deleteTask(int id) async {
    final db = await database;

    final old = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (old.isEmpty) return;

    final year = old.first['year'] as int;
    final number = old.first['number'].toString();

    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    await SyncManager.deleteTask(
      year: year,
      number: number,
    );

    await addChangeLog(
      entityType: 'Zadanie',
      entityId: id.toString(),
      action: 'Usunięcie',
      oldValue: '$number | $year',
      newValue: '',
    );
  }

  static Future<void> insertYear(int year) async {
    final db = await database;

    await db.insert(
      'years',
      {'year': year},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await addChangeLog(
      entityType: 'Rok',
      entityId: year.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: year.toString(),
    );
    await SyncManager.sendYear(year: year);
  }

  static Future<List<Map<String, dynamic>>> getYears() async {
    final db = await database;

    return db.query(
      'years',
      orderBy: 'year DESC',
    );
  }
  static Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    final currentUserId = await getCurrentUserId();

    return db.rawQuery('''
      SELECT 
        m.*,
        CASE 
          WHEN r.id IS NULL THEN 0
          ELSE 1
        END AS isRead
      FROM messages m
      LEFT JOIN message_reads r
        ON r.message_uuid = m.message_uuid
        AND r.userId = ?
      WHERE m.deleted = 0
      ORDER BY
        CASE 
          WHEN m.level = 'WAŻNE' THEN 0
          WHEN m.level = 'ISTOTNE' THEN 1
          ELSE 2
        END,
        m.id DESC
    ''', [currentUserId]);
  }

  static Future<Map<String, dynamic>> insertMessage(
    String title,
    String text,
    String level,
    String dateTime,
    String userId, {
    String? imagePath,
  }) async {
    final db = await database;
    final messageUuid = const Uuid().v4();

    String? serverImagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      serverImagePath = await UploadManager.uploadFile(imagePath);
    }

    final id = await db.insert('messages', {
      'message_uuid': messageUuid,
      'title': title,
      'text': text,
      'level': level,
      'dateTime': dateTime,
      'userId': userId,
      'imagePath': imagePath,
      'serverImagePath': serverImagePath,
      'deleted': 0,
    });

    await addChangeLog(
      entityType: 'Komunikat',
      entityId: id.toString(),
      action: 'Dodanie',
      oldValue: '',
      newValue: '$title | $level',
    );

    final sent = await SyncManager.sendMessage(
      messageUuid: messageUuid,
      title: title,
      text: text,
      level: level,
      dateTime: dateTime,
      userId: userId,
      serverImagePath: serverImagePath,
    );

    return {
      'sent': sent,
      'messageUuid': messageUuid,
    };
  }

  static Future<void> upsertMessageImageFromServer({
    required String imageUuid,
    required String messageUuid,
    String? serverImagePath,
    String caption = '',
    bool deleted = false,
  }) async {
    if (imageUuid.isEmpty || messageUuid.isEmpty) return;

    final db = await database;

    if (deleted) {
      await db.update(
        'message_images',
        {'deleted': 1},
        where: 'image_uuid = ?',
        whereArgs: [imageUuid],
      );
      return;
    }

    final existing = await db.query(
      'message_images',
      where: 'image_uuid = ?',
      whereArgs: [imageUuid],
      limit: 1,
    );

    String? localImagePath;

    if (serverImagePath != null && serverImagePath.isNotEmpty) {
      localImagePath = await DownloadManager.downloadFile(serverImagePath);
    }

    final oldImagePath =
        existing.isNotEmpty ? existing.first['imagePath']?.toString() : null;

    final finalImagePath = localImagePath != null && localImagePath.isNotEmpty
        ? localImagePath
        : oldImagePath;

    await db.insert(
      'message_images',
      {
        'image_uuid': imageUuid,
        'message_uuid': messageUuid,
        'imagePath': finalImagePath,
        'serverImagePath': serverImagePath,
        'caption': caption,
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> insertMessageImage(
    String messageUuid,
    String imagePath, {
    String caption = '',
  }) async {
    if (messageUuid.isEmpty || imagePath.isEmpty) return;

    final db = await database;
    final imageUuid = const Uuid().v4();

    final serverImagePath = await UploadManager.uploadFile(imagePath);

    await db.insert('message_images', {
      'image_uuid': imageUuid,
      'message_uuid': messageUuid,
      'imagePath': imagePath,
      'serverImagePath': serverImagePath,
      'caption': caption,
      'deleted': 0,
    });

    await SyncManager.sendMessageImage(
      imageUuid: imageUuid,
      messageUuid: messageUuid,
      serverImagePath: serverImagePath,
      caption: caption,
    );
  }

  static Future<List<Map<String, dynamic>>> getMessageImages(
    String messageUuid,
  ) async {
    final db = await database;

    return db.query(
      'message_images',
      where: 'message_uuid = ? AND deleted = 0',
      whereArgs: [messageUuid],
      orderBy: 'id ASC',
    );
  }

  static Future<String?> getFirstMessageImagePath(String messageUuid) async {
    final db = await database;

    final result = await db.query(
      'message_images',
      columns: ['imagePath'],
      where:
          'message_uuid = ? AND deleted = 0 AND imagePath IS NOT NULL AND imagePath != ""',
      whereArgs: [messageUuid],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['imagePath']?.toString();
  }

  static Future<void> upsertMessageFromServer({
    required String messageUuid,
    required String title,
    required String text,
    required String level,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    if (messageUuid.isEmpty) return;

    final db = await database;

    if (deleted) {
      await db.update(
        'messages',
        {'deleted': 1},
        where: 'message_uuid = ?',
        whereArgs: [messageUuid],
      );
      return;
    }

    final existing = await db.query(
      'messages',
      where: 'message_uuid = ?',
      whereArgs: [messageUuid],
      limit: 1,
    );

    String? localImagePath;

    if (serverImagePath != null && serverImagePath.isNotEmpty) {
      localImagePath = await DownloadManager.downloadFile(serverImagePath);
    }

    final oldImagePath = existing.isNotEmpty
        ? existing.first['imagePath']?.toString()
        : null;

    final finalImagePath =
        localImagePath != null && localImagePath.isNotEmpty
            ? localImagePath
            : oldImagePath;

    await db.insert(
      'messages',
      {
        'message_uuid': messageUuid,
        'title': title,
        'text': text,
        'level': level,
        'dateTime': dateTime,
        'userId': userId,
        'imagePath': finalImagePath,
        'serverImagePath': serverImagePath,
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> upsertMessageReadFromServer({
    required String messageUuid,
    required String userId,
    required String readAt,
  }) async {
    if (messageUuid.isEmpty || userId.isEmpty) return;

    final db = await database;

    await db.insert(
      'message_reads',
      {
        'message_uuid': messageUuid,
        'userId': userId,
        'readAt': readAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> markMessageAsRead(int id) async {
    final db = await database;
    final currentUserId = await getCurrentUserId();

    final result = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return;

    final messageUuid = result.first['message_uuid']?.toString() ?? '';
    if (messageUuid.isEmpty) return;

    final readAt = DateTime.now().toString();

    await db.insert(
      'message_reads',
      {
        'message_uuid': messageUuid,
        'userId': currentUserId,
        'readAt': readAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await SyncManager.markMessageRead(
      messageUuid: messageUuid,
      userId: currentUserId,
      readAt: readAt,
    );
  }

  static Future<List<String>> getMessageReadUserNames(int messageId) async {
    final db = await database;

    final message = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );

    if (message.isEmpty) return [];

    final messageUuid = message.first['message_uuid']?.toString() ?? '';
    if (messageUuid.isEmpty) return [];

    final rows = await db.rawQuery('''
      SELECT u.name
      FROM message_reads r
      LEFT JOIN users u ON u.id = r.userId
      WHERE r.message_uuid = ?
      ORDER BY u.name ASC
    ''', [messageUuid]);

    return rows
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Future<int> getUnreadMessagesCount() async {
    final db = await database;
    final currentUserId = await getCurrentUserId();

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM messages m
      LEFT JOIN message_reads r
        ON r.message_uuid = m.message_uuid
        AND r.userId = ?
      WHERE m.deleted = 0
        AND r.id IS NULL
    ''', [currentUserId]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> deleteMessage(int id) async {
    final db = await database;

    final old = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (old.isEmpty) return;

    final message = old.first;
    final messageUuid = message['message_uuid']?.toString() ?? '';

    await db.update(
      'messages',
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (messageUuid.isNotEmpty) {
      await SyncManager.sendMessage(
        messageUuid: messageUuid,
        title: message['title']?.toString() ?? '',
        text: message['text']?.toString() ?? '',
        level: message['level']?.toString() ?? 'OGŁOSZENIA',
        dateTime: message['dateTime']?.toString() ?? '',
        userId: message['userId']?.toString() ?? 'USER_001',
        serverImagePath: message['serverImagePath']?.toString(),
        deleted: true,
      );
    }

    await addChangeLog(
      entityType: 'Komunikat',
      entityId: id.toString(),
      action: 'Usunięcie',
      oldValue:
          '${message['title']} | ${message['text']} | ${message['level']}',
      newValue: '',
    );
  }

  static Future<void> updateMessage(
    int id,
    String title,
    String text,
    String level,
  ) async {
    final db = await database;

    final old = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (old.isEmpty) return;

    final message = old.first;
    final messageUuid = message['message_uuid']?.toString() ?? '';

    final oldValue =
        '${message['title']} | ${message['text']} | ${message['level']}';
    final newValue = '$title | $text | $level';

    await db.update(
      'messages',
      {
        'title': title,
        'text': text,
        'level': level,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (messageUuid.isNotEmpty) {
      await SyncManager.sendMessage(
        messageUuid: messageUuid,
        title: title,
        text: text,
        level: level,
        dateTime: message['dateTime']?.toString() ?? '',
        userId: message['userId']?.toString() ?? 'USER_001',
        serverImagePath: message['serverImagePath']?.toString(),
      );
    }

    await addChangeLog(
      entityType: 'Komunikat',
      entityId: id.toString(),
      action: 'Edycja',
      oldValue: oldValue,
      newValue: newValue,
    );
  }
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;

    return db.query(
      'users',
      orderBy: 'name ASC',
    );
  }

  static Future<void> insertUser(String id, String name) async {
    final db = await database;

    await db.insert(
      'users',
      {
        'id': id,
        'name': name,
        'isAdmin': 0,
        'role': 'USER',
        'pin': '0000',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await SyncManager.sendUser(
      id: id,
      name: name,
      role: 'USER',
      pin: '0000',
    );

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Dodanie',
      oldValue: '',
      newValue: '$name | USER',
    );
  }

    static Future<void> upsertUserFromServer({
      required String id,
      required String name,
      required String role,
      required String pin,
    }) async {
      final db = await database;

      await db.insert(
        'users',
        {
          'id': id,
          'name': name,
          'role': role,
          'pin': pin,
          'isAdmin': role == 'ADMIN' ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

  static Future<String> getCurrentUserId() async {
    final db = await database;

    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['currentUserId'],
      limit: 1,
    );

    if (result.isEmpty) return 'USER_001';

    return result.first['value']?.toString() ?? 'USER_001';
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final userId = await getCurrentUserId();

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  static Future<void> setCurrentUserId(String userId) async {
    final db = await database;

    await db.insert(
      'app_settings',
      {
        'key': 'currentUserId',
        'value': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  static Future<String> getUserNameById(String userId) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return userId;

    return result.first['name']?.toString() ?? userId;
  }
  static Future<void> updateUserName(String id, String name) async {
    final db = await database;

    final old = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty ? '' : old.first['name']?.toString() ?? '';

    await db.update(
      'users',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );

    final user = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (user.isNotEmpty) {
      await SyncManager.sendUser(
        id: id,
        name: name,
        role: user.first['role']?.toString() ?? 'USER',
        pin: user.first['pin']?.toString() ?? '0000',
      );
    }

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Edycja nazwy',
      oldValue: oldValue,
      newValue: name,
    );
  }

  static Future<void> deleteUser(String id) async {
    final db = await database;

    final old = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldValue = old.isEmpty
        ? ''
        : '${old.first['name']} | ${old.first['role']}';

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    await SyncManager.deleteUser(id);

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Usunięcie',
      oldValue: oldValue,
      newValue: '',
    );
  }

  static Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();

    return user?['isAdmin'] == 1;
  }
  static Future<bool> checkUserPin(String userId, String pin) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ? AND pin = ?',
      whereArgs: [userId, pin],
      limit: 1,
    );

    return result.isNotEmpty;
  }
  static Future<void> updateUserPin(String id, String pin) async {
    final db = await database;

    await db.update(
      'users',
      {'pin': pin},
      where: 'id = ?',
      whereArgs: [id],
    );

    final user = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (user.isNotEmpty) {
      await SyncManager.sendUser(
        id: id,
        name: user.first['name']?.toString() ?? '',
        role: user.first['role']?.toString() ?? 'USER',
        pin: pin,
      );
    }

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Zmiana PIN',
      oldValue: '****',
      newValue: '****',
    );
  }

  static Future<void> resetUserPin(String id) async {
    final db = await database;

    await db.update(
      'users',
      {'pin': '0000'},
      where: 'id = ?',
      whereArgs: [id],
    );

    final user = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (user.isNotEmpty) {
      await SyncManager.sendUser(
        id: id,
        name: user.first['name']?.toString() ?? '',
        role: user.first['role']?.toString() ?? 'USER',
        pin: '0000',
      );
    }

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Reset PIN',
      oldValue: '****',
      newValue: '0000',
    );
  }

  static Future<void> logout() async {
    final db = await database;

    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['currentUserId'],
    );
  }
  static Future<void> updateUserRole(String id, String role) async {
    final db = await database;

    final old = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldRole = old.isEmpty
        ? ''
        : old.first['role']?.toString() ?? 'USER';

    await db.update(
      'users',
      {
        'role': role,
        'isAdmin': role == 'ADMIN' ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final user = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (user.isNotEmpty) {
      await SyncManager.sendUser(
        id: id,
        name: user.first['name']?.toString() ?? '',
        role: role,
        pin: user.first['pin']?.toString() ?? '0000',
      );
    }

    await addChangeLog(
      entityType: 'Użytkownik',
      entityId: id,
      action: 'Zmiana roli',
      oldValue: oldRole,
      newValue: role,
    );
  }

  static Future<String> getCurrentUserRole() async {
    final user = await getCurrentUser();

    return user?['role']?.toString() ?? 'USER';
  }


  static Future<bool> isCurrentUserExpert() async {
    final user = await getCurrentUser();

    if (user == null) return false;

    final role = user['role']?.toString() ?? 'USER';
    final isAdmin = user['isAdmin'] == 1;

    return isAdmin || role == 'ADMIN' || role == 'EKSPERT';
  }

  static Future<bool> canCurrentUserEditItem(String itemUserId) async {
    final user = await getCurrentUser();

    if (user == null) return false;

    final role = user['role']?.toString() ?? 'USER';
    final isAdmin = user['isAdmin'] == 1;

    if (isAdmin || role == 'ADMIN') return true;

    final currentId = await getCurrentUserId();

    return currentId == itemUserId;
  }

  static Future<bool> canCurrentUserAddImportantMessages() async {
    final user = await getCurrentUser();

    if (user == null) return false;

    final role = user['role']?.toString() ?? 'USER';
    final isAdmin = user['isAdmin'] == 1;

    return isAdmin || role == 'ADMIN' || role == 'EKSPERT';
  }

  static Future<void> addChangeLog({
    required String entityType,
    required String entityId,
    required String action,
    String? oldValue,
    String? newValue,
  }) async {
    final db = await database;

    final userId = await getCurrentUserId();
    final userName = await getUserNameById(userId);

    await db.insert('change_logs', {
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'oldValue': oldValue,
      'newValue': newValue,
      'userId': userId,
      'userName': userName,
      'dateTime': DateTime.now().toString(),
    });
  }

  static Future<List<Map<String, dynamic>>> getChangeLogs() async {
    final db = await database;

    return db.query(
      'change_logs',
      orderBy: 'id DESC',
    );
  }
  static Future<Map<String, int>> getAdminStats() async {
    final db = await database;

    Future<int> count(String table, {String? where}) async {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $table ${where == null ? '' : 'WHERE $where'}',
      );

      return Sqflite.firstIntValue(result) ?? 0;
    }

    return {
      'users': await count('users'),
      'years': await count('years'),
      'tasks': await count('tasks'),
      'entries': await count('entries'),
      'photos': await count(
        'entries',
        where: 'imagePath IS NOT NULL AND imagePath != ""',
      ),
      'cars': await count('cars'),
      'carNotes': await count('car_notes'),
      'messages': await count('messages'),
      'changeLogs': await count('change_logs'),
    };
  }
  static Future<String> createBackupZip({
    void Function(double progress)? onProgress,
  }) async {
    final db = await database;

    await db.close();
    _db = null;

    final dbPath = await getDatabasesPath();
    final sourceDbPath = join(dbPath, 'wto.db');

    final appDir = await getApplicationDocumentsDirectory();

    final now = DateTime.now();

    final fileName =
        'WTO_Backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}.zip';

    final externalDir = await getExternalStorageDirectory();

    if (externalDir == null) {
      throw Exception('Nie udało się znaleźć katalogu zapisu.');
    }

    final backupDir = Directory('${externalDir.path}/WTO_Backup');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final backupPath = '${backupDir.path}/$fileName';

    final encoder = ZipFileEncoder();

    encoder.create(backupPath);
    onProgress?.call(0.05);

    encoder.addFile(File(sourceDbPath), 'wto.db');
    onProgress?.call(0.15);

    final files = appDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !file.path.endsWith('.zip'))
        .where((file) => file.path != sourceDbPath)
        .toList();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final relativePath = file.path.replaceFirst('${appDir.path}/', '');

      encoder.addFile(file, 'files/$relativePath');

      final progress = 0.15 + ((i + 1) / files.length) * 0.75;
      onProgress?.call(progress);
    }

    encoder.close();

    final reopenedDb = await database;

    await addChangeLog(
      entityType: 'Backup',
      entityId: fileName,
      action: 'Utworzenie',
      oldValue: '',
      newValue: backupPath,
    );
    onProgress?.call(1.0);
    return backupPath;
  }
  static Future<List<FileSystemEntity>> getBackupFiles() async {
    final externalDir = await getExternalStorageDirectory();

    if (externalDir == null) return [];

    final backupDir = Directory('${externalDir.path}/WTO_Backup');

    if (!await backupDir.exists()) return [];

    final files = backupDir
        .listSync()
        .where((file) => file.path.endsWith('.zip'))
        .toList();

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );

    return files;
  }

    static Future<void> restoreBackupFromPath(
    String backupZipPath, {
    void Function(double progress)? onProgress,
  }) async {
    final db = await database;
    await db.close();
    _db = null;

    final dbPath = await getDatabasesPath();
    final targetDbPath = join(dbPath, 'wto.db');

    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/restore_temp');

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }

    await tempDir.create(recursive: true);

    final bytes = await File(backupZipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    onProgress?.call(0.10);

    for (int i = 0; i < archive.length; i++) {
      final file = archive[i];
      final filePath = '${tempDir.path}/${file.name}';

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }

      final progress = 0.10 + ((i + 1) / archive.length) * 0.45;
      onProgress?.call(progress);
    }

    final restoredDb = File('${tempDir.path}/wto.db');

    if (!await restoredDb.exists()) {
      throw Exception('Backup nie zawiera pliku wto.db');
    }

    onProgress?.call(0.60);
    await restoredDb.copy(targetDbPath);

    final restoredFilesDir = Directory('${tempDir.path}/files');

    if (await restoredFilesDir.exists()) {
      final files = restoredFilesDir
          .listSync(recursive: true)
          .whereType<File>()
          .toList();

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final relativePath =
            file.path.replaceFirst('${restoredFilesDir.path}/', '');

        final targetFile = File('${appDir.path}/$relativePath');

        await targetFile.create(recursive: true);
        await file.copy(targetFile.path);

        final progress = 0.60 + ((i + 1) / files.length) * 0.35;
        onProgress?.call(progress);
      }
    }

    await tempDir.delete(recursive: true);

    _db = null;

    onProgress?.call(1.0);
  }

  static Future<void> deleteBackup(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
  
  static Future<void> syncUsersFromServer() async {
    try {
      final users = await WtoApi.getUsers();

      for (final user in users) {
        final id = user['id'].toString();
        final deleted = user['deleted']?.toString() == '1';

        if (deleted) {
          final db = await database;

          await db.delete(
            'users',
            where: 'id = ?',
            whereArgs: [id],
          );

          continue;
        }

        await upsertUserFromServer(
          id: id,
          name: user['name'].toString(),
          role: user['role'].toString(),
          pin: user['pin'].toString(),
        );
      }
    } catch (e) {
      print('Błąd synchronizacji users: $e');
    }
  }
  static Future<void> syncYearsFromServer() async {
    try {
      final years = await WtoApi.getYears();

      final db = await database;

      for (final item in years) {
        final year = item['year'];
        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (year == null) continue;

        if (deleted) {
          await db.delete(
            'years',
            where: 'year = ?',
            whereArgs: [year],
          );
          continue;
        }

        await db.insert(
          'years',
          {
            'year': year,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    } catch (e) {
      print('Błąd synchronizacji years: $e');
    }
  }

  static Future<void> syncTasksFromServer() async {
    try {
      final tasks = await WtoApi.getTasks();

      final db = await database;

      for (final item in tasks) {
        final year = item['year'];
        final number = item['number']?.toString();
        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (year == null || number == null || number.isEmpty) continue;

        if (deleted) {
          await db.delete(
            'tasks',
            where: 'year = ? AND number = ?',
            whereArgs: [year, number],
          );
          continue;
        }

        final existing = await db.query(
          'tasks',
          where: 'year = ? AND number = ?',
          whereArgs: [year, number],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert(
            'tasks',
            {
              'year': year,
              'number': number,
            },
          );
        }
      }
    } catch (e) {
      print('Błąd synchronizacji tasks: $e');
    }
  }
  static Future<void> upsertEntryFromServer({
    required String entryUuid,
    required String number,
    required String category,
    required String text,
    required String dateTime,
    String? imagePath,
    String? serverImagePath,
    required String userId,
  }) async {
    final db = await database;

    final existing = await db.query(
      'entries',
      where: 'entry_uuid = ?',
      whereArgs: [entryUuid],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'entries',
        {
          'number': number,
          'category': category,
          'text': text,
          'dateTime': dateTime,
          'imagePath': imagePath,
          'serverImagePath': serverImagePath,
          'userId': userId,
        },
        where: 'entry_uuid = ?',
        whereArgs: [entryUuid],
      );
      return;
    }

    await db.insert(
      'entries',
      {
        'entry_uuid': entryUuid,
        'number': number,
        'category': category,
        'text': text,
        'dateTime': dateTime,
        'imagePath': imagePath,
        'serverImagePath': serverImagePath,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> syncEntriesFromServer() async {
    try {
      final entries = await WtoApi.getEntries();

      final db = await database;

      for (final item in entries) {
        final entryUuid = item['entry_uuid']?.toString();
        final number = item['number']?.toString();
        final category = item['category']?.toString() ?? 'WPIS';
        final text = item['text']?.toString() ?? '';
        final dateTime = item['dateTime']?.toString() ?? '';
        final serverImagePath = item['imagePath']?.toString();

        String? localImagePath;

        if (serverImagePath != null && serverImagePath.isNotEmpty) {
          localImagePath =
              await DownloadManager.downloadFile(serverImagePath);
        }
        final userId = item['userId']?.toString() ?? 'USER_001';
        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (entryUuid == null || entryUuid.isEmpty) continue;
        if (number == null || number.isEmpty) continue;

        if (deleted) {
          await db.delete(
            'entries',
            where: 'entry_uuid = ?',
            whereArgs: [entryUuid],
          );
          continue;
        }

        await upsertEntryFromServer(
          entryUuid: entryUuid,
          number: number,
          category: category,
          text: text,
          dateTime: dateTime,
          imagePath: localImagePath,
          serverImagePath: serverImagePath,
          userId: userId,
        );
      }
    } catch (e) {
      print('Błąd synchronizacji entries: $e');
    }
  }
  static Future<void> upsertCarFromServer({
    required String carUuid,
    required String name,
    required String plate,
    required String createdAt,
    required int colorIndex,
  }) async {
    final db = await database;

    final existing = await db.query(
      'cars',
      where: 'car_uuid = ?',
      whereArgs: [carUuid],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'cars',
        {
          'name': name,
          'plate': plate,
          'createdAt': createdAt,
          'colorIndex': colorIndex,
        },
        where: 'car_uuid = ?',
        whereArgs: [carUuid],
      );
      return;
    }

    await db.insert(
      'cars',
      {
        'car_uuid': carUuid,
        'name': name,
        'plate': plate,
        'createdAt': createdAt,
        'colorIndex': colorIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> syncCarsFromServer() async {
    try {
      final cars = await WtoApi.getCars();

      final db = await database;

      for (final item in cars) {
        final carUuid = item['car_uuid']?.toString();
        final name = item['name']?.toString() ?? '';
        final plate = item['plate']?.toString() ?? '';
        final createdAt = item['createdAt']?.toString() ?? '';
        final colorIndex =
            int.tryParse(item['colorIndex']?.toString() ?? '0') ?? 0;

        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (carUuid == null || carUuid.isEmpty) continue;

        if (deleted) {
          await db.delete(
            'cars',
            where: 'car_uuid = ?',
            whereArgs: [carUuid],
          );
          continue;
        }

        await upsertCarFromServer(
          carUuid: carUuid,
          name: name,
          plate: plate,
          createdAt: createdAt,
          colorIndex: colorIndex,
        );
      }
    } catch (e) {
      print('Błąd synchronizacji cars: $e');
    }
  }
  static Future<void> upsertCarTermsFromServer({
    required String carUuid,
    String? ocDate,
    String? acDate,
    String? btDate,
  }) async {
    final db = await database;

    final carResult = await db.query(
      'cars',
      where: 'car_uuid = ?',
      whereArgs: [carUuid],
      limit: 1,
    );

    if (carResult.isEmpty) return;

    final carId = carResult.first['id'] as int;

    final existing = await db.query(
      'car_terms',
      where: 'carId = ?',
      whereArgs: [carId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'car_terms',
        {
          'ocDate': ocDate,
          'acDate': acDate,
          'btDate': btDate,
        },
        where: 'carId = ?',
        whereArgs: [carId],
      );
      return;
    }

    await db.insert(
      'car_terms',
      {
        'carId': carId,
        'ocDate': ocDate,
        'acDate': acDate,
        'btDate': btDate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  static Future<void> syncCarTermsFromServer() async {
    try {
      final terms = await WtoApi.getCarTerms();

      final db = await database;

      for (final item in terms) {
        final carUuid = item['car_uuid']?.toString();
        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (carUuid == null || carUuid.isEmpty) continue;

        final carResult = await db.query(
          'cars',
          where: 'car_uuid = ?',
          whereArgs: [carUuid],
          limit: 1,
        );

        if (carResult.isEmpty) continue;

        final carId = carResult.first['id'] as int;

        if (deleted) {
          await db.delete(
            'car_terms',
            where: 'carId = ?',
            whereArgs: [carId],
          );
          continue;
        }

        await upsertCarTermsFromServer(
          carUuid: carUuid,
          ocDate: item['ocDate']?.toString(),
          acDate: item['acDate']?.toString(),
          btDate: item['btDate']?.toString(),
        );
      }
    } catch (e) {
      print('Błąd synchronizacji car_terms: $e');
    }
  }
  static Future<void> upsertCarNoteFromServer({
    required String carNoteUuid,
    required String carUuid,
    required String section,
    required String text,
    required String dateTime,
    required String userId,
    String? imagePath,
    String? serverImagePath,
  }) async {
    final db = await database;

    final carResult = await db.query(
      'cars',
      where: 'car_uuid = ?',
      whereArgs: [carUuid],
      limit: 1,
    );

    if (carResult.isEmpty) return;

    final carId = carResult.first['id'] as int;

    final existing = await db.query(
      'car_notes',
      where: 'car_note_uuid = ?',
      whereArgs: [carNoteUuid],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'car_notes',
        {
          'carId': carId,
          'section': section,
          'text': text,
          'dateTime': dateTime,
          'userId': userId,
          'imagePath': imagePath,
          'serverImagePath': serverImagePath,
        },
        where: 'car_note_uuid = ?',
        whereArgs: [carNoteUuid],
      );
      return;
    }

    await db.insert(
      'car_notes',
      {
        'car_note_uuid': carNoteUuid,
        'carId': carId,
        'section': section,
        'text': text,
        'dateTime': dateTime,
        'userId': userId,
        'imagePath': imagePath,
        'serverImagePath': serverImagePath,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> syncCarNotesFromServer() async {
    try {
      final notes = await WtoApi.getCarNotes();

      final db = await database;

      for (final item in notes) {
        final carNoteUuid = item['car_note_uuid']?.toString();
        final carUuid = item['car_uuid']?.toString();
        final section = item['section']?.toString() ?? '';
        final text = item['text']?.toString() ?? '';
        final dateTime = item['dateTime']?.toString() ?? '';
        final userId = item['userId']?.toString() ?? 'USER_001';
        final serverImagePath = item['imagePath']?.toString();

        final deleted = item['deleted']?.toString() == '1' ||
            item['deleted'] == true;

        if (carNoteUuid == null || carNoteUuid.isEmpty) continue;
        if (carUuid == null || carUuid.isEmpty) continue;

        final carResult = await db.query(
          'cars',
          where: 'car_uuid = ?',
          whereArgs: [carUuid],
          limit: 1,
        );

        if (carResult.isEmpty) continue;

        final carId = carResult.first['id'] as int;

        if (deleted) {
          await db.delete(
            'car_notes',
            where: 'car_note_uuid = ?',
            whereArgs: [carNoteUuid],
          );
          continue;
        }

        String? localImagePath;

        if (serverImagePath != null && serverImagePath.isNotEmpty) {
          localImagePath = await DownloadManager.downloadFile(serverImagePath);
        }

        await upsertCarNoteFromServer(
          carNoteUuid: carNoteUuid,
          carUuid: carUuid,
          section: section,
          text: text,
          dateTime: dateTime,
          userId: userId,
          imagePath: localImagePath,
          serverImagePath: serverImagePath,
        );
      }
    } catch (e) {
      print('Błąd synchronizacji car_notes: $e');
    }
  }
}