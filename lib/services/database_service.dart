import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/memo.dart';

class DatabaseService {
  static const _tableName = 'memos';
  static const _dbVersion = 2;

  final String? path;
  Database? _db;

  DatabaseService({this.path});

  Future<void> open() async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'chocotto_memo.db');
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            emoji TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN updated_at TEXT NOT NULL DEFAULT ""',
          );
          await db.execute(
            'UPDATE $_tableName SET updated_at = created_at',
          );
        }
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<int> insert(Memo memo) async {
    return await _db!.insert(_tableName, memo.toMap());
  }

  Future<List<Memo>> getAll({int? limit, int? offset}) async {
    final rows = await _db!.query(
      _tableName,
      orderBy: 'updated_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Memo.fromMap).toList();
  }

  Future<void> update(Memo memo) async {
    final map = memo.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db!.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<void> delete(int id) async {
    await _db!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
