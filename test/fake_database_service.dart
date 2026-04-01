import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/services/database_service.dart';

/// ウィジェットテスト用のFakeDatabaseService。
/// sqflite_common_ffi はアイソレートを使うため testWidgets の FakeAsync 環境で動かない。
/// このFakeはリストを使ってインメモリで動作し、Futureがマイクロタスクで即完了する。
class FakeDatabaseService extends DatabaseService {
  int _nextId = 1;
  final List<Memo> _memos = [];

  /// trueにするとinsert/update/deleteが例外を投げる
  bool shouldThrow = false;

  /// getAll呼び出し回数
  int getAllCallCount = 0;

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
  Future<List<Memo>> getAll({int? limit, int? offset}) async {
    getAllCallCount++;
    final sorted = [..._memos]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final start = offset ?? 0;
    final sliced = start >= sorted.length ? <Memo>[] : sorted.sublist(start);
    return limit == null ? sliced : sliced.take(limit).toList();
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
}
