import 'package:chocotto_memo/models/memo.dart';
import 'package:chocotto_memo/services/database_service.dart';

/// ウィジェットテスト用のFakeDatabaseService。
/// sqflite_common_ffi はアイソレートを使うため testWidgets の FakeAsync 環境で動かない。
/// このFakeはリストを使ってインメモリで動作し、Futureがマイクロタスクで即完了する。
class FakeDatabaseService extends DatabaseService {
  int _nextId = 1;
  final List<Memo> _memos = [];

  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}

  @override
  Future<int> insert(Memo memo) async {
    final id = _nextId++;
    _memos.add(Memo(
      id: id,
      title: memo.title,
      content: memo.content,
      emoji: memo.emoji,
      createdAt: memo.createdAt,
    ));
    return id;
  }

  @override
  Future<List<Memo>> getAll() async {
    return [..._memos]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> update(Memo memo) async {
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index >= 0) _memos[index] = memo;
  }

  @override
  Future<void> delete(int id) async {
    _memos.removeWhere((m) => m.id == id);
  }
}
