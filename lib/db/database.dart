import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wto.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            text TEXT,
            dateTime TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertEntry(String number, String text, String dateTime) async {
    final db = await database;

    await db.insert('entries', {
      'number': number,
      'text': text,
      'dateTime': dateTime,
    });
  }

  static Future<List<Map<String, dynamic>>> getEntries(String number) async {
    final db = await database;

    return db.query(
      'entries',
      where: 'number = ?',
      whereArgs: [number],
      orderBy: 'id ASC',
    );
  }
}