import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/memo.dart';
import '../models/memo_view.dart';
import '../models/view_item.dart';

class DatabaseService {
  static const _tableName = 'memos';
  static const _dbVersion = 3;

  final String? path;
  Database? _db;

  DatabaseService({this.path});

  Future<void> open() async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'chocotto_memo.db');
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
        await db.execute('''
          CREATE TABLE views (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            display_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE view_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            view_id INTEGER NOT NULL REFERENCES views(id) ON DELETE CASCADE,
            memo_id INTEGER NOT NULL REFERENCES $_tableName(id) ON DELETE CASCADE,
            pos_index INTEGER NOT NULL,
            UNIQUE(view_id, pos_index)
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
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE views (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              display_order INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE view_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              view_id INTEGER NOT NULL REFERENCES views(id) ON DELETE CASCADE,
              memo_id INTEGER NOT NULL REFERENCES $_tableName(id) ON DELETE CASCADE,
              pos_index INTEGER NOT NULL,
              UNIQUE(view_id, pos_index)
            )
          ''');
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

  Future<List<Memo>> getAll() async {
    final rows = await _db!.query(
      _tableName,
      orderBy: 'updated_at DESC',
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

  // --- Views ---

  Future<void> insertView(MemoView view) async {
    await _db!.insert('views', view.toMap());
  }

  Future<List<MemoView>> getViews() async {
    final rows = await _db!.query('views', orderBy: 'display_order ASC');
    return rows.map(MemoView.fromMap).toList();
  }

  Future<void> deleteView(int id) async {
    await _db!.delete('views', where: 'id = ?', whereArgs: [id]);
  }

  // --- ViewItems ---

  Future<int> insertViewItem(ViewItem item) async {
    return await _db!.insert('view_items', item.toMap());
  }

  Future<List<ViewItem>> getViewItems(int viewId) async {
    final rows = await _db!.query(
      'view_items',
      where: 'view_id = ?',
      whereArgs: [viewId],
    );
    return rows.map(ViewItem.fromMap).toList();
  }

  Future<void> deleteViewItem(int id) async {
    await _db!.delete('view_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, Memo>> getGridMemos(int viewId) async {
    final rows = await _db!.rawQuery('''
      SELECT vi.pos_index, m.*
      FROM view_items vi
      JOIN $_tableName m ON vi.memo_id = m.id
      WHERE vi.view_id = ?
    ''', [viewId]);

    final result = <int, Memo>{};
    for (final row in rows) {
      final posIndex = row['pos_index'] as int;
      result[posIndex] = Memo.fromMap(row);
    }
    return result;
  }
}
