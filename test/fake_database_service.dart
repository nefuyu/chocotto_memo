import 'dart:async';

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

  // --- getAll の呼び出し番号別一時停止機構 (Completerベース) ---
  int _getAllCallIndex = 0;
  final Map<int, Completer<void>> _getAllHold = {};

  /// [callIndex] 番目（1始まり）の getAll 呼び出しを一時停止させる
  void holdGetAllCallAt(int callIndex) {
    _getAllHold[callIndex] = Completer<void>();
  }

  /// [callIndex] 番目の停止中 getAll を解放する
  void releaseGetAllCallAt(int callIndex) {
    _getAllHold[callIndex]?.complete();
  }

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
    final callIdx = ++_getAllCallIndex;
    if (_getAllHold.containsKey(callIdx)) {
      await _getAllHold[callIdx]!.future;
    }
    final sorted = [..._memos]
      ..sort((a, b) {
        final cmp = b.updatedAt.compareTo(a.updatedAt);
        if (cmp != 0) return cmp;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });
    final start = offset ?? 0;
    final sliced = sorted.skip(start);
    return (limit == null ? sliced : sliced.take(limit)).toList();
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
