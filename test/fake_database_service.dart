import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/models/memo_view.dart';
import 'package:chocotto_memo/models/view_item.dart';
import 'package:chocotto_memo/services/database_service.dart';

/// ウィジェットテスト用のFakeDatabaseService。
/// sqflite_common_ffi はアイソレートを使うため testWidgets の FakeAsync 環境で動かない。
/// このFakeはリストを使ってインメモリで動作し、Futureがマイクロタスクで即完了する。
class FakeDatabaseService extends DatabaseService {
  int _nextId = 1;
  final List<Memo> _memos = [];

  int _nextViewItemId = 1;
  final List<MemoView> _views = [];
  final List<ViewItem> _viewItems = [];

  /// trueにするとinsert/update/deleteが例外を投げる
  bool shouldThrow = false;

  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}

  @override
  Future<int> insert(Memo memo) async {
    if (shouldThrow) throw Exception('DB error');
    final id = _nextId++;
    _memos.add(Memo(
      id: id,
      title: memo.title,
      content: memo.content,
      emoji: memo.emoji,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
    ));
    return id;
  }

  @override
  Future<List<Memo>> getAll() async {
    return [..._memos]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> update(Memo memo) async {
    if (shouldThrow) throw Exception('DB error');
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index >= 0) {
      _memos[index] = Memo(
        id: memo.id,
        title: memo.title,
        content: memo.content,
        emoji: memo.emoji,
        createdAt: memo.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    if (shouldThrow) throw Exception('DB error');
    _memos.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> insertView(MemoView view) async {
    _views.add(view);
  }

  @override
  Future<List<MemoView>> getViews() async {
    return [..._views]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  Future<void> deleteView(int id) async {
    _views.removeWhere((v) => v.id == id);
    _viewItems.removeWhere((vi) => vi.viewId == id);
  }

  @override
  Future<int> insertViewItem(ViewItem item) async {
    final id = _nextViewItemId++;
    _viewItems.add(ViewItem(
      id: id,
      viewId: item.viewId,
      memoId: item.memoId,
      posIndex: item.posIndex,
    ));
    return id;
  }

  @override
  Future<List<ViewItem>> getViewItems(int viewId) async {
    return _viewItems.where((vi) => vi.viewId == viewId).toList();
  }

  @override
  Future<void> deleteViewItem(int id) async {
    _viewItems.removeWhere((vi) => vi.id == id);
  }

  @override
  Future<Map<int, Memo>> getGridMemos(int viewId) async {
    final items = _viewItems.where((vi) => vi.viewId == viewId).toList();
    final result = <int, Memo>{};
    for (final item in items) {
      final memo = _memos.firstWhere((m) => m.id == item.memoId);
      result[item.posIndex] = memo;
    }
    return result;
  }
}
