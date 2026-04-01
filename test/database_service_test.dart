import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;

  setUp(() async {
    db = DatabaseService(path: inMemoryDatabasePath);
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  group('Memo.toMap / fromMap', () {
    test('toMap includes all fields', () {
      final memo = Memo(
        id: 1,
        title: 'タイトル',
        content: '本文',
        emoji: '📝',
        createdAt: DateTime(2026, 3, 24),
        updatedAt: DateTime(2026, 3, 25),
      );
      final map = memo.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'タイトル');
      expect(map['content'], '本文');
      expect(map['emoji'], '📝');
      expect(map['created_at'], '2026-03-24T00:00:00.000');
      expect(map['updated_at'], '2026-03-25T00:00:00.000');
    });

    test('fromMap restores Memo correctly', () {
      final map = {
        'id': 2,
        'title': 'テスト',
        'content': '内容',
        'emoji': '🔥',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-02T00:00:00.000',
      };
      final memo = Memo.fromMap(map);
      expect(memo.id, 2);
      expect(memo.title, 'テスト');
      expect(memo.content, '内容');
      expect(memo.emoji, '🔥');
      expect(memo.createdAt, DateTime(2026, 1, 1));
      expect(memo.updatedAt, DateTime(2026, 1, 2));
    });
  });

  group('DatabaseService CRUD', () {
    test('insert and getAll returns the memo', () async {
      final now = DateTime(2026, 3, 24);
      final memo = Memo(
        title: 'Hello',
        content: 'World',
        emoji: '👋',
        createdAt: now,
        updatedAt: now,
      );
      await db.insert(memo);
      final all = await db.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'Hello');
      expect(all.first.id, isNotNull);
    });

    test('update changes memo fields and sets updatedAt to now', () async {
      final createdAt = DateTime(2026, 3, 24);
      final memo = Memo(
        title: '旧タイトル',
        content: '旧内容',
        emoji: '😴',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final id = await db.insert(memo);
      final beforeUpdate = DateTime.now();
      final updated = Memo(
        id: id,
        title: '新タイトル',
        content: '新内容',
        emoji: '🎉',
        createdAt: createdAt,
        updatedAt: createdAt, // サービス側で上書きされる
      );
      await db.update(updated);
      final afterUpdate = DateTime.now();
      final all = await db.getAll();
      expect(all.length, 1);
      expect(all.first.title, '新タイトル');
      expect(all.first.emoji, '🎉');
      // updatedAt がupdate呼び出し時刻付近に更新されていること
      expect(
        all.first.updatedAt.isAfter(beforeUpdate.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        all.first.updatedAt.isBefore(afterUpdate.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('delete removes the memo', () async {
      final now = DateTime(2026, 3, 24);
      final id = await db.insert(Memo(
        title: '削除対象',
        content: '',
        emoji: '🗑️',
        createdAt: now,
        updatedAt: now,
      ));
      await db.delete(id);
      final all = await db.getAll();
      expect(all, isEmpty);
    });

    test('getAll returns memos sorted by updatedAt descending', () async {
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 3, 24);
      await db.insert(Memo(
        title: '古い',
        content: '',
        emoji: '📅',
        createdAt: old,
        updatedAt: old,
      ));
      await db.insert(Memo(
        title: '新しい',
        content: '',
        emoji: '🆕',
        createdAt: recent,
        updatedAt: recent,
      ));
      final all = await db.getAll();
      expect(all.first.title, '新しい');
      expect(all.last.title, '古い');
    });

    test('multiple inserts accumulate', () async {
      final now = DateTime(2026, 3, 24);
      for (var i = 0; i < 3; i++) {
        await db.insert(Memo(
          title: 'メモ$i',
          content: '',
          emoji: '📌',
          createdAt: now,
          updatedAt: now,
        ));
      }
      final all = await db.getAll();
      expect(all.length, 3);
    });
  });

  group('DatabaseService ページネーション', () {
    Future<void> insertMemos(int count) async {
      for (var i = 0; i < count; i++) {
        await db.insert(Memo(
          title: 'メモ$i',
          content: '',
          emoji: '📌',
          createdAt: DateTime(2026, 1, 1, 0, 0, i),
          updatedAt: DateTime(2026, 1, 1, 0, 0, i),
        ));
      }
    }

    test('limitを指定すると指定件数だけ返る', () async {
      await insertMemos(5);
      final result = await db.getAll(limit: 3);
      expect(result.length, 3);
    });

    test('offsetを指定すると先頭をスキップして返る', () async {
      await insertMemos(5);
      final all = await db.getAll();
      final paged = await db.getAll(limit: 3, offset: 2);
      expect(paged.length, 3);
      expect(paged.first.title, all[2].title);
    });

    test('offsetが総件数以上のときは空リストを返す', () async {
      await insertMemos(3);
      final result = await db.getAll(limit: 10, offset: 10);
      expect(result, isEmpty);
    });

    test('limitなしの場合は全件返る', () async {
      await insertMemos(5);
      final result = await db.getAll();
      expect(result.length, 5);
    });
  });
}
