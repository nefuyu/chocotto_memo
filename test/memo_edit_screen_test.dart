import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/screens/memo_edit_screen.dart';
import 'fake_database_service.dart';

void main() {
  late FakeDatabaseService db;

  setUp(() {
    db = FakeDatabaseService();
  });

  Future<void> pumpEditScreen(WidgetTester tester, {Memo? memo}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoEditScreen(db: db, memo: memo),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MemoEditScreen - 新規作成', () {
    testWidgets('「新規作成」タイトルが表示される', (WidgetTester tester) async {
      await pumpEditScreen(tester);
      expect(find.text('新規作成'), findsOneWidget);
    });

    testWidgets('タイトル・本文・絵文字の入力フィールドが表示される', (WidgetTester tester) async {
      await pumpEditScreen(tester);
      expect(find.text('タイトル'), findsOneWidget);
      expect(find.text('本文'), findsOneWidget);
      expect(find.text('絵文字'), findsOneWidget);
    });

    testWidgets('保存ボタンが表示される', (WidgetTester tester) async {
      await pumpEditScreen(tester);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('絵文字フィールドにデフォルト値が入っている', (WidgetTester tester) async {
      await pumpEditScreen(tester);
      // フィールド順: 0=絵文字, 1=タイトル, 2=本文
      final emojiField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(emojiField.controller?.text, '📝');
    });

    testWidgets('タイトルを入力して保存するとDBに保存される', (WidgetTester tester) async {
      await pumpEditScreen(tester);

      await tester.enterText(find.byType(TextField).at(1), 'テストタイトル');
      await tester.enterText(find.byType(TextField).at(2), 'テスト本文');

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final memos = await db.getAll();
      expect(memos.length, 1);
      expect(memos.first.title, 'テストタイトル');
      expect(memos.first.content, 'テスト本文');
    });
  });

  group('MemoEditScreen - 編集', () {
    testWidgets('「編集」タイトルが表示される', (WidgetTester tester) async {
      final id = await db.insert(Memo(
        title: '既存タイトル',
        content: '既存本文',
        emoji: '🔥',
        createdAt: DateTime(2024, 1, 1),
      ));
      final memo = (await db.getAll()).first;
      await pumpEditScreen(tester, memo: memo);

      expect(find.text('編集'), findsOneWidget);
    });

    testWidgets('既存メモの値がフィールドに入っている', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '既存タイトル',
        content: '既存本文',
        emoji: '🔥',
        createdAt: DateTime(2024, 1, 1),
      ));
      final memo = (await db.getAll()).first;
      await pumpEditScreen(tester, memo: memo);

      final emojiField = tester.widget<TextField>(find.byType(TextField).at(0));
      final titleField = tester.widget<TextField>(find.byType(TextField).at(1));
      final contentField = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(emojiField.controller?.text, '🔥');
      expect(titleField.controller?.text, '既存タイトル');
      expect(contentField.controller?.text, '既存本文');
    });

    testWidgets('編集して保存するとDBが更新される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '旧タイトル',
        content: '旧本文',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
      ));
      final memo = (await db.getAll()).first;
      await pumpEditScreen(tester, memo: memo);

      await tester.enterText(find.byType(TextField).at(1), '新タイトル');

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final memos = await db.getAll();
      expect(memos.length, 1);
      expect(memos.first.title, '新タイトル');
    });
  });

  group('MemoEditScreen - バリデーション', () {
    testWidgets('タイトルが空のまま保存するとSnackBarが表示される', (WidgetTester tester) async {
      await pumpEditScreen(tester);

      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('タイトルを入力してください'), findsOneWidget);
    });

    testWidgets('タイトルが空のときDBには保存されない', (WidgetTester tester) async {
      await pumpEditScreen(tester);

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(await db.getAll(), isEmpty);
    });
  });

  group('MemoEditScreen - DB例外ハンドリング', () {
    testWidgets('新規作成でDB例外が発生するとSnackBarが表示される', (WidgetTester tester) async {
      db.shouldThrow = true;
      await pumpEditScreen(tester);

      await tester.enterText(find.byType(TextField).at(1), 'タイトル');
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('保存に失敗しました'), findsOneWidget);
    });

    testWidgets('編集でDB例外が発生するとSnackBarが表示される', (WidgetTester tester) async {
      db.shouldThrow = false;
      await db.insert(Memo(
        title: '既存',
        content: '',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
      ));
      final memo = (await db.getAll()).first;
      db.shouldThrow = true;
      await pumpEditScreen(tester, memo: memo);

      await tester.enterText(find.byType(TextField).at(1), '更新後');
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('保存に失敗しました'), findsOneWidget);
    });
  });
}
