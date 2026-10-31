import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite 单例。Android/iOS 走平台原生 SQLite（sqflite 插件）。
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'tastemap.db');
    return openDatabase(
      path,
      version: 2,
      onUpgrade: (db, old, version) async {
        if (old < 2) {
          for (final name in [
            'province',
            'district',
            'adcode',
            'amap_id',
            'address',
          ]) {
            await db.execute('ALTER TABLE places ADD COLUMN $name TEXT');
          }
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE places (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        city TEXT,
        country TEXT,
        province TEXT, district TEXT, adcode TEXT, amap_id TEXT, address TEXT,
        type TEXT NOT NULL DEFAULT 'custom',
        source TEXT,
        foursquare_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        place_id TEXT NOT NULL,
        primary_tag TEXT NOT NULL,
        secondary_tags TEXT NOT NULL DEFAULT '[]',
        note TEXT NOT NULL DEFAULT '',
        images TEXT NOT NULL DEFAULT '[]',
        visited_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 清理用：关闭连接。
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
