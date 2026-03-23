import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('メモがある場合にリストが表示される', (WidgetTester tester) async {
      final memos = [
        Memo(
          title: 'テストメモ1',
          content: 'テスト内容1',
          emoji: '📝',
          createdAt: DateTime(2024, 1, 15),
        ),
        Memo(
          title: 'テストメモ2',
          content: 'テスト内容2',
          emoji: '✅',
          createdAt: DateTime(2024, 1, 10),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(memos: memos),
      ));

      expect(find.text('テストメモ1'), findsOneWidget);
      expect(find.text('テストメモ2'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('メモがない場合に空メッセージが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: HomeScreen(memos: []),
      ));

      expect(
        find.text('メモがありません。右下のボタンから作成しましょう'),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('メモが降順（新しい順）で表示される', (WidgetTester tester) async {
      final memos = [
        Memo(
          title: '古いメモ',
          content: '内容',
          emoji: '📝',
          createdAt: DateTime(2024, 1, 1),
        ),
        Memo(
          title: '新しいメモ',
          content: '内容',
          emoji: '✅',
          createdAt: DateTime(2024, 6, 1),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(memos: memos),
      ));

      final newMemoIndex = tester
          .getTopLeft(find.text('新しいメモ'))
          .dy;
      final oldMemoIndex = tester
          .getTopLeft(find.text('古いメモ'))
          .dy;

      expect(newMemoIndex, lessThan(oldMemoIndex));
    });

    testWidgets('FABが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: HomeScreen(memos: []),
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
