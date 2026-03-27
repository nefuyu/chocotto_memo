import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/utils/memo_utils.dart';
import 'package:chocotto_memo/models/memo.dart';

void main() {
  final now = DateTime.now();

  group('MemoUtils.sortByTitle', () {
    test('タイトルの昇順でソートされること', () {
      final memos = [
        Memo(title: 'C', content: '', emoji: '', createdAt: now),
        Memo(title: 'A', content: '', emoji: '', createdAt: now),
        Memo(title: 'B', content: '', emoji: '', createdAt: now),
      ];
      final sorted = MemoUtils.sortByTitle(memos);
      expect(sorted.map((m) => m.title).toList(), ['A', 'B', 'C']);
    });
  });

  group('MemoUtils.search', () {
    final memos = [
      Memo(title: 'Flutter', content: 'モバイル開発', emoji: '', createdAt: now),
      Memo(title: 'Dart', content: 'プログラミング言語', emoji: '', createdAt: now),
    ];

    test('クエリが空のとき全件返すこと', () {
      expect(MemoUtils.search(memos, '').length, 2);
    });

    test('一致するメモを返すこと', () {
      expect(MemoUtils.search(memos, 'Flutter').length, 1);
    });
  });

  group('MemoUtils.truncate', () {
    test('maxLength文字でちょうど切り詰められること', () {
      expect(MemoUtils.truncate('Hello World', 5), 'Hello...');
    });
  });

  group('MemoUtils.totalCharCount', () {
    test('全メモの文字数合計を返すこと', () {
      final memos = [
        Memo(title: 'AB', content: 'CD', emoji: '', createdAt: now),
        Memo(title: 'EF', content: 'GH', emoji: '', createdAt: now),
      ];
      expect(MemoUtils.totalCharCount(memos), 8);
    });
  });
}
