import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/screens/home_screen.dart';
import 'package:chocotto_memo/screens/memo_edit_screen.dart';
import 'package:chocotto_memo/screens/settings_screen.dart';
import 'package:chocotto_memo/services/settings_service.dart';
import 'fake_database_service.dart';

void main() {
  late FakeDatabaseService db;
  late SettingsNotifier settingsNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeDatabaseService();
    settingsNotifier = SettingsNotifier(SettingsService());
    await settingsNotifier.load();
  });

  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(db: db, settingsNotifier: settingsNotifier)),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets('メモがある場合にリストが表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: 'テストメモ1',
        content: 'テスト内容1',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ));
      await db.insert(Memo(
        title: 'テストメモ2',
        content: 'テスト内容2',
        emoji: '✅',
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      ));

      await pumpHomeScreen(tester);

      expect(find.text('テストメモ1'), findsOneWidget);
      expect(find.text('テストメモ2'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('メモがない場合に空メッセージが表示される', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      expect(
        find.text('メモがありません。右下のボタンから作成しましょう'),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('メモが降順（新しい順）で表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '古いメモ',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));
      await db.insert(Memo(
        title: '新しいメモ',
        content: '内容',
        emoji: '✅',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      ));

      await pumpHomeScreen(tester);

      final newMemoIndex = tester.getTopLeft(find.text('新しいメモ')).dy;
      final oldMemoIndex = tester.getTopLeft(find.text('古いメモ')).dy;

      expect(newMemoIndex, lessThan(oldMemoIndex));
    });

    testWidgets('FABが表示される', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FABをタップするとMemoEditScreenへ遷移する', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(MemoEditScreen), findsOneWidget);
    });

    testWidgets('メモをタップするとMemoEditScreenへ遷移する', (WidgetTester tester) async {
      await db.insert(Memo(
        title: 'タップテスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      expect(find.byType(MemoEditScreen), findsOneWidget);
    });

    testWidgets('AppBarに設定アイコンボタンが表示される', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('設定アイコンをタップするとSettingsScreenへ遷移する', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('HomeScreen - 無限スクロール', () {
    testWidgets('メモが100件以下の場合はローディングインジケータが表示されない', (WidgetTester tester) async {
      await db.insert(Memo(
        title: 'メモ1',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('スクロール末尾到達時に次のページが追加読み込みされる', (WidgetTester tester) async {
      // 101件挿入してページをまたぐ状況を作る
      for (var i = 0; i < 101; i++) {
        await db.insert(Memo(
          title: 'メモ$i',
          content: '内容',
          emoji: '📝',
          createdAt: DateTime(2024, 1, 1, 0, 0, i),
          updatedAt: DateTime(2024, 1, 1, 0, 0, i),
        ));
      }

      await pumpHomeScreen(tester);

      // 最初は100件分しか表示されていない
      expect(db.getAllCallCount, 1);

      // 末尾までスクロール
      await tester.drag(find.byType(ListView), const Offset(0, -10000));
      await tester.pumpAndSettle();

      // 追加読み込みが発生している
      expect(db.getAllCallCount, greaterThan(1));
    });

    testWidgets('全件読み込み済みの場合は追加読み込みされない', (WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await db.insert(Memo(
          title: 'メモ$i',
          content: '内容',
          emoji: '📝',
          createdAt: DateTime(2024, 1, 1, 0, 0, i),
          updatedAt: DateTime(2024, 1, 1, 0, 0, i),
        ));
      }

      await pumpHomeScreen(tester);
      final countAfterInit = db.getAllCallCount;

      await tester.drag(find.byType(ListView), const Offset(0, -10000));
      await tester.pumpAndSettle();

      // 全件読み込み済みのため追加読み込みなし
      expect(db.getAllCallCount, countAfterInit);
    });
  });

  group('HomeScreen - 削除機能', () {
    testWidgets('メモを長押しするとコンテキストメニューが表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '削除テスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      await tester.longPress(find.text('削除テスト'));
      await tester.pumpAndSettle();

      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('コンテキストメニューの「削除」を選ぶと確認ダイアログが表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '削除テスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      await tester.longPress(find.text('削除テスト'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(find.text('削除しますか？'), findsOneWidget);
    });

    testWidgets('確認ダイアログで「削除」をタップするとメモが削除される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '削除テスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      await tester.longPress(find.text('削除テスト'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      // AlertDialog内の「削除」ボタン
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pumpAndSettle();

      expect(find.text('削除テスト'), findsNothing);
      expect(
        find.text('メモがありません。右下のボタンから作成しましょう'),
        findsOneWidget,
      );
    });

    testWidgets('確認ダイアログで「キャンセル」をタップするとメモが残る', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '削除テスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      await tester.longPress(find.text('削除テスト'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('削除テスト'), findsOneWidget);
    });

    testWidgets('DB削除失敗時にSnackBarが表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: '削除テスト',
        content: '内容',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ));

      await pumpHomeScreen(tester);

      db.shouldThrow = true;
      await tester.longPress(find.text('削除テスト'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pump();

      expect(find.text('削除に失敗しました'), findsOneWidget);
    });
  });
}
