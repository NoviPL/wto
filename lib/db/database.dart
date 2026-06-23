import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    await db.insert('cars', {
      'name': name,
      'plate': plate,
      'createdAt': createdAt,
      'colorIndex': colorIndex,
    });
  }

  static Future<void> updateCar(
    int id,
    String name,
    String plate,
  ) async {
    final db = await database;

    await db.update(
      'cars',
      {
        'name': name,
        'plate': plate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteCar(int id) async {
    final db = await database;

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

    await db.insert('car_notes', {
      'carId': carId,
      'section': section,
      'text': text,
      'dateTime': dateTime,
      'userId': userId,
      'imagePath': imagePath,
    });
  }

  static Future<void> updateCarNote(
    int id,
    String text,
  ) async {
    final db = await database;

    await db.update(
      'car_notes',
      {
        'text': text,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteCarNote(int id) async {
    final db = await database;

    await db.delete(
      'car_notes',
      where: 'id = ?',
      whereArgs: [id],
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
      version: 12,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            category TEXT,
            text TEXT,
            dateTime TEXT,
            imagePath TEXT,
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
            name TEXT NOT NULL,
            plate TEXT,
            createdAt TEXT,
            colorIndex INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE car_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            carId INTEGER NOT NULL,
            section TEXT NOT NULL,
            text TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            userId TEXT NOT NULL,
            imagePath TEXT
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
            title TEXT NOT NULL,
            text TEXT NOT NULL,
            level TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            userId TEXT NOT NULL,
            isRead INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            isAdmin INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.insert('users', {
          'id': 'USER_001',
          'name': 'Użytkownik 1',
          'isAdmin': 1,
        });

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

    await db.insert('entries', {
      'number': number,
      'category': category,
      'text': text,
      'dateTime': dateTime,
      'imagePath': imagePath,
      'userId': userId,
    });
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

    await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> insertTask(int year, String number) async {
    final db = await database;

    await db.insert('tasks', {
      'year': year,
      'number': number,
    });
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
  static Future<void> insertYear(int year) async {
    final db = await database;

    await db.insert(
      'years',
      {'year': year},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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

    return db.query(
      'messages',
      orderBy: '''
        CASE 
          WHEN level = 'WAŻNE' THEN 0
          ELSE 1
        END,
        id DESC
      ''',
    );
  }

  static Future<void> insertMessage(
    String title,
    String text,
    String level,
    String dateTime,
    String userId,
  ) async {
    final db = await database;

    await db.insert('messages', {
      'title': title,
      'text': text,
      'level': level,
      'dateTime': dateTime,
      'userId': userId,
      'isRead': 0,
    });
  }

  static Future<void> markMessageAsRead(int id) async {
    final db = await database;

    await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getUnreadMessagesCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE isRead = 0',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> deleteMessage(int id) async {
    final db = await database;

    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
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
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
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

    await db.update(
      'users',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteUser(String id) async {
    final db = await database;

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();

    return user?['isAdmin'] == 1;
  }
}