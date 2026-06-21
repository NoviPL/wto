import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            text TEXT,
            dateTime TEXT,
            imagePath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER,
            number TEXT
          )   
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN imagePath TEXT');
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
      },
    );
  }

  static Future<void> insertEntry(
    String number,
    String text,
    String dateTime,
    String? imagePath,
  ) async {
    final db = await database;

    await db.insert('entries', {
      'number': number,
      'text': text,
      'dateTime': dateTime,
      'imagePath': imagePath,
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
      orderBy: 'id ASC',
    );
  }
}
}