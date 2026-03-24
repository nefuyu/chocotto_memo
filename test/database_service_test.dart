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
      );
      final map = memo.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'タイトル');
      expect(map['content'], '本文');
      expect(map['emoji'], '📝');
      expect(map['created_at'], '2026-03-24T00:00:00.000');
    });

    test('fromMap restores Memo correctly', () {
      final map = {
        'id': 2,
        'title': 'テスト',
        'content': '内容',
        'emoji': '🔥',
        'created_at': '2026-01-01T00:00:00.000',
      };
      final memo = Memo.fromMap(map);
      expect(memo.id, 2);
      expect(memo.title, 'テスト');
      expect(memo.content, '内容');
      expect(memo.emoji, '🔥');
      expect(memo.createdAt, DateTime(2026, 1, 1));
    });
  });

  group('DatabaseService CRUD', () {
    test('insert and getAll returns the memo', () async {
      final memo = Memo(
        title: 'Hello',
        content: 'World',
        emoji: '👋',
        createdAt: DateTime(2026, 3, 24),
      );
      await db.insert(memo);
      final all = await db.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'Hello');
      expect(all.first.id, isNotNull);
    });

    test('update changes memo fields', () async {
      final memo = Memo(
        title: '旧タイトル',
        content: '旧内容',
        emoji: '😴',
        createdAt: DateTime(2026, 3, 24),
      );
      final id = await db.insert(memo);
      final updated = Memo(
        id: id,
        title: '新タイトル',
        content: '新内容',
        emoji: '🎉',
        createdAt: memo.createdAt,
      );
      await db.update(updated);
      final all = await db.getAll();
      expect(all.length, 1);
      expect(all.first.title, '新タイトル');
      expect(all.first.emoji, '🎉');
    });

    test('delete removes the memo', () async {
      final id = await db.insert(Memo(
        title: '削除対象',
        content: '',
        emoji: '🗑️',
        createdAt: DateTime(2026, 3, 24),
      ));
      await db.delete(id);
      final all = await db.getAll();
      expect(all, isEmpty);
    });

    test('getAll returns memos sorted by createdAt descending', () async {
      await db.insert(Memo(
        title: '古い',
        content: '',
        emoji: '📅',
        createdAt: DateTime(2026, 1, 1),
      ));
      await db.insert(Memo(
        title: '新しい',
        content: '',
        emoji: '🆕',
        createdAt: DateTime(2026, 3, 24),
      ));
      final all = await db.getAll();
      expect(all.first.title, '新しい');
      expect(all.last.title, '古い');
    });

    test('multiple inserts accumulate', () async {
      for (var i = 0; i < 3; i++) {
        await db.insert(Memo(
          title: 'メモ$i',
          content: '',
          emoji: '📌',
          createdAt: DateTime(2026, 3, 24),
        ));
      }
      final all = await db.getAll();
      expect(all.length, 3);
    });
  });
}
