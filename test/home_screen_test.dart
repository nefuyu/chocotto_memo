import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/screens/home_screen.dart';
import 'package:chocotto_memo/screens/memo_edit_screen.dart';
import 'fake_database_service.dart';

void main() {
  late FakeDatabaseService db;

  setUp(() {
    db = FakeDatabaseService();
  });

  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(db: db)));
    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets('メモがある場合にリストが表示される', (WidgetTester tester) async {
      await db.insert(Memo(
        title: 'テストメモ1',
        content: 'テスト内容1',
        emoji: '📝',
        createdAt: DateTime(2024, 1, 15),
      ));
      await db.insert(Memo(
        title: 'テストメモ2',
        content: 'テスト内容2',
        emoji: '✅',
        createdAt: DateTime(2024, 1, 10),
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
      ));
      await db.insert(Memo(
        title: '新しいメモ',
        content: '内容',
        emoji: '✅',
        createdAt: DateTime(2024, 6, 1),
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
      ));

      await pumpHomeScreen(tester);

      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      expect(find.byType(MemoEditScreen), findsOneWidget);
    });
  });
}
