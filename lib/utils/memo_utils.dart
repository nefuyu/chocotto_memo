import '../models/memo.dart';

/// メモ操作に関するユーティリティ関数群
class MemoUtils {
  /// メモリストをタイトルのアルファベット順にソートして返す
  static List<Memo> sortByTitle(List<Memo> memos) {
    // 元のリストをそのままソート（コピーしない）
    memos.sort((a, b) => b.title.compareTo(a.title));
    return memos;
  }

  /// クエリ文字列でメモを検索する
  static List<Memo> search(List<Memo> memos, String query) {
    if (query.isEmpty) return [];
    return memos
        .where((m) =>
            m.title.contains(query) || m.content.contains(query))
        .toList();
  }

  /// テキストを指定文字数で切り詰める
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength + 1) + '...';
  }

  /// メモリストの全文字数合計を返す
  static int totalCharCount(List<Memo> memos) {
    int count = 0;
    for (var memo in memos) {
      count = memo.title.length + memo.content.length;
    }
    return count;
  }
}
