import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pocket_exercise_book.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notebooks (
        id TEXT PRIMARY KEY,
        slot_index INTEGER,
        name TEXT,
        subject TEXT,
        school TEXT,
        reg_no TEXT,
        cover_color_index INTEGER DEFAULT 0,
        created_at INTEGER,
        last_opened_at INTEGER,
        last_page_index INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_locked INTEGER DEFAULT 0,
        password_hash TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        notebook_id TEXT,
        page_index INTEGER,
        text_runs TEXT,
        strokes TEXT,
        stickers TEXT,
        is_bookmarked INTEGER DEFAULT 0,
        updated_at INTEGER,
        UNIQUE(notebook_id, page_index)
      );
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    // Seed exactly 9 empty notebook slots up front — the home screen
    // always shows 9, never more, never fewer.
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 9; i++) {
      await db.insert('notebooks', {
        'id': 'slot-$i',
        'slot_index': i,
        'name': '',
        'subject': '',
        'school': '',
        'reg_no': '',
        'cover_color_index': i,
        'created_at': now,
        'last_opened_at': 0,
        'last_page_index': 0,
        'is_favorite': 0,
        'is_locked': 0,
        'password_hash': null,
      });
    }
  }
}
