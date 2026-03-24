import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/memo.dart';

class DatabaseService {
  static const _tableName = 'memos';
  static const _dbVersion = 1;

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
            created_at TEXT NOT NULL
          )
        ''');
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

  Future<List<Memo>> getAll() async {
    final rows = await _db!.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(Memo.fromMap).toList();
  }

  Future<void> update(Memo memo) async {
    await _db!.update(
      _tableName,
      memo.toMap(),
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
