import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/models/memo_view.dart';
import 'package:chocotto_memo/models/view_item.dart';
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

  group('View CRUD', () {
    test('insertViewとgetViewsでビューが取得できる', () async {
      final view = MemoView(id: 1, name: 'テストビュー', displayOrder: 0);
      await db.insertView(view);
      final views = await db.getViews();
      expect(views.length, 1);
      expect(views.first.id, 1);
      expect(views.first.name, 'テストビュー');
      expect(views.first.displayOrder, 0);
    });

    test('getViewsはdisplay_order昇順で返す', () async {
      await db.insertView(MemoView(id: 2, name: 'B', displayOrder: 2));
      await db.insertView(MemoView(id: 1, name: 'A', displayOrder: 1));
      final views = await db.getViews();
      expect(views[0].name, 'A');
      expect(views[1].name, 'B');
    });

    test('deleteViewでビューが削除される', () async {
      await db.insertView(MemoView(id: 1, name: 'テストビュー', displayOrder: 0));
      await db.deleteView(1);
      expect(await db.getViews(), isEmpty);
    });
  });

  group('ViewItem CRUD', () {
    late int memoId;

    setUp(() async {
      await db.insertView(MemoView(id: 1, name: 'テストビュー', displayOrder: 0));
      memoId = await db.insert(Memo(
        title: 'テストメモ',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
    });

    test('insertViewItemとgetViewItemsでアイテムが取得できる', () async {
      final id = await db.insertViewItem(
        ViewItem(viewId: 1, memoId: memoId, posIndex: 0),
      );
      final items = await db.getViewItems(1);
      expect(items.length, 1);
      expect(items.first.id, id);
      expect(items.first.viewId, 1);
      expect(items.first.memoId, memoId);
      expect(items.first.posIndex, 0);
    });

    test('deleteViewItemでアイテムが削除される', () async {
      final id = await db.insertViewItem(
        ViewItem(viewId: 1, memoId: memoId, posIndex: 0),
      );
      await db.deleteViewItem(id);
      expect(await db.getViewItems(1), isEmpty);
    });

    test('deleteViewはview_itemsをカスケード削除する', () async {
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));
      await db.deleteView(1);
      expect(await db.getViews(), isEmpty);
      // カスケード後、view_idが消えたビューのアイテムは存在しない
      final items = await db.getViewItems(1);
      expect(items, isEmpty);
    });

    test('getGridMemosはpos_indexをキーにMemoを返す', () async {
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 2));
      final grid = await db.getGridMemos(1);
      expect(grid.containsKey(2), isTrue);
      expect(grid[2]!.id, memoId);
      expect(grid[2]!.title, 'テストメモ');
    });

    test('getGridMemosはアイテムがない場合に空マップを返す', () async {
      final grid = await db.getGridMemos(1);
      expect(grid, isEmpty);
    });

    test('同じビューの同じpos_indexへの重複配置は例外となる', () async {
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));
      expect(
        () async => db.insertViewItem(
          ViewItem(viewId: 1, memoId: memoId, posIndex: 0),
        ),
        throwsException,
      );
    });
  });
}
