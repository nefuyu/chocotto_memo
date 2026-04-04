import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/models/memo_view.dart';
import 'package:chocotto_memo/models/view_item.dart';
import 'package:chocotto_memo/screens/grid_view_screen.dart';
import 'package:chocotto_memo/screens/memo_edit_screen.dart';
import 'fake_database_service.dart';

void main() {
  late FakeDatabaseService db;
  late MemoView testView;

  setUp(() async {
    db = FakeDatabaseService();
    testView = const MemoView(id: 1, name: 'テストビュー', displayOrder: 0);
    await db.insertView(testView);
  });

  Future<void> pumpGridViewScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GridViewScreen(view: testView, db: db)),
    );
    await tester.pumpAndSettle();
  }

  group('GridViewScreen', () {
    testWidgets('AppBarにビュー名が表示される', (tester) async {
      await pumpGridViewScreen(tester);
      expect(find.text('テストビュー'), findsOneWidget);
    });

    testWidgets('3×3の9セルが表示される', (tester) async {
      await pumpGridViewScreen(tester);
      // GridViewが存在し、9つのセルウィジェットが表示される
      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('grid_cell_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('grid_cell_8')),
        findsOneWidget,
      );
    });

    testWidgets('配置されたメモのタイトルがセルに表示される', (tester) async {
      final memoId = await db.insert(Memo(
        title: 'グリッドメモ',
        content: '内容',
        emoji: '🗂️',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));

      await pumpGridViewScreen(tester);

      expect(find.text('グリッドメモ'), findsOneWidget);
      expect(find.text('🗂️'), findsOneWidget);
    });

    testWidgets('複数のメモが正しいセル位置に表示される', (tester) async {
      final memo1Id = await db.insert(Memo(
        title: 'メモA',
        content: '',
        emoji: '🅰️',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      final memo2Id = await db.insert(Memo(
        title: 'メモB',
        content: '',
        emoji: '🅱️',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memo1Id, posIndex: 0));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memo2Id, posIndex: 4));

      await pumpGridViewScreen(tester);

      expect(find.text('メモA'), findsOneWidget);
      expect(find.text('メモB'), findsOneWidget);
    });

    testWidgets('メモがないビューではすべてのセルが空として表示される', (tester) async {
      await pumpGridViewScreen(tester);
      // メモが一切ない
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(MemoEditScreen), findsNothing);
    });

    testWidgets('メモセルをタップするとMemoEditScreenへ遷移する', (tester) async {
      final memoId = await db.insert(Memo(
        title: 'タップメモ',
        content: '内容',
        emoji: '👆',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));

      await pumpGridViewScreen(tester);

      await tester.tap(find.text('タップメモ'));
      await tester.pumpAndSettle();

      expect(find.byType(MemoEditScreen), findsOneWidget);
    });

    testWidgets('空セルをタップしても遷移しない', (tester) async {
      await pumpGridViewScreen(tester);

      // pos_index=0の空セルをタップ
      await tester.tap(find.byKey(const ValueKey<String>('grid_cell_0')));
      await tester.pumpAndSettle();

      expect(find.byType(MemoEditScreen), findsNothing);
    });

    testWidgets('MemoEditScreenから戻るとグリッドが再読み込みされる', (tester) async {
      final memoId = await db.insert(Memo(
        title: '編集前メモ',
        content: '内容',
        emoji: '✏️',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));

      await pumpGridViewScreen(tester);
      expect(find.text('編集前メモ'), findsOneWidget);

      await tester.tap(find.text('編集前メモ'));
      await tester.pumpAndSettle();

      // MemoEditScreenから戻る
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // グリッドが再表示される
      expect(find.byType(GridViewScreen), findsOneWidget);
    });
  });

  group('GridViewScreen - Error Recovery', () {
    testWidgets('グリッド読み込みに失敗するとSnackBarが表示される', (tester) async {
      db.shouldThrowOnGetGrid = true;
      await pumpGridViewScreen(tester);
      expect(find.text('メモの読み込みに失敗しました'), findsOneWidget);
    });

    testWidgets('エラー後もグリッド画面が表示され続ける（スタックしない）',
        (tester) async {
      db.shouldThrowOnGetGrid = true;
      await pumpGridViewScreen(tester);
      expect(find.text('メモの読み込みに失敗しました'), findsOneWidget);
      // エラーが発生しても画面はそのまま表示される
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('FakeDatabaseService - posIndex バリデーション', () {
    test('insertViewItemでposIndexが0未満はArgumentErrorとなる', () async {
      final memoId = await db.insert(Memo(
        title: 'テスト',
        content: '',
        emoji: '📝',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      expect(
        () async => db.insertViewItem(
          ViewItem(viewId: 1, memoId: memoId, posIndex: -1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('insertViewItemでposIndexが9以上はArgumentErrorとなる', () async {
      final memoId = await db.insert(Memo(
        title: 'テスト',
        content: '',
        emoji: '📝',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      expect(
        () async => db.insertViewItem(
          ViewItem(viewId: 1, memoId: memoId, posIndex: 9),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GridViewScreen - Accessibility', () {
    testWidgets('メモセルにスクリーンリーダー向けラベルが付与される', (tester) async {
      final memoId = await db.insert(Memo(
        title: 'アクセシビリティテスト',
        content: '内容',
        emoji: '♿',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.insertViewItem(ViewItem(viewId: 1, memoId: memoId, posIndex: 0));

      await pumpGridViewScreen(tester);

      expect(
        find.bySemanticsLabel(RegExp('アクセシビリティテスト')),
        findsWidgets,
      );
    });

    testWidgets('空セルにスクリーンリーダー向けラベルが付与される', (tester) async {
      await pumpGridViewScreen(tester);

      expect(
        find.bySemanticsLabel(RegExp('空のセル')),
        findsWidgets,
      );
    });
  });
}
