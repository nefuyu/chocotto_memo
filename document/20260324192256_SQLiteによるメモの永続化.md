# 5_SQLiteによるメモの永続化

## Issue概要

メモデータがメモリ上にのみ存在し、アプリを閉じると消える問題を解決する。
`sqflite` を使ってローカルDBに保存・復元できるようにする。

## 実装方針

- `sqflite` + `path` パッケージを追加し、端末ローカルのSQLiteに保存する。
- `Memo` モデルにDB用の `id` フィールドおよびシリアライズメソッドを追加する。
- `DatabaseService` クラスにCRUD操作を集約し、画面側から利用しやすい形にする。
- テストは `sqflite_common_ffi` を使ってインメモリDBで実行し、Flutter環境に依存しない。

## クラス／関数構成

### `lib/models/memo.dart` — `Memo`

| メンバー | 説明 |
|---------|------|
| `int? id` | DB上の主キー。新規作成時は `null`、保存後に採番される。 |
| `toMap()` | DBへのinsert/update用に `Map<String, dynamic>` へ変換する。`id` が `null` の場合はマップに含めない（AUTOINCREMENTに任せる）。 |
| `Memo.fromMap(map)` | DBから取得した行データを `Memo` インスタンスに復元するファクトリコンストラクタ。 |

### `lib/services/database_service.dart` — `DatabaseService`

| メンバー | 説明 |
|---------|------|
| `DatabaseService({String? path})` | `path` を省略すると端末の標準DBパスを使用。テスト時は `inMemoryDatabasePath` を渡す。 |
| `open()` | DBを開く（テーブルが存在しない場合は `onCreate` で作成）。 |
| `close()` | DBを閉じる。 |
| `insert(Memo)` → `Future<int>` | メモを挿入し、採番された `id` を返す。 |
| `getAll()` → `Future<List<Memo>>` | 全メモを `created_at` 降順で取得する。 |
| `update(Memo)` | `id` を条件にメモを更新する。 |
| `delete(int id)` | `id` を条件にメモを削除する。 |

### DBスキーマ

```sql
CREATE TABLE memos (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,
  emoji      TEXT NOT NULL,
  created_at TEXT NOT NULL   -- ISO8601形式で保存
)
```

## テスト方針

- `sqflite_common_ffi` を使い、`inMemoryDatabasePath` でインメモリDBを使用。
- `setUpAll` で `sqfliteFfiInit()` を呼び出し、`setUp`/`tearDown` でDB開閉を行う。
- 各テストは独立したDBインスタンスを使うため、テスト間の干渉がない。

| テスト名 | 検証内容 |
|---------|---------|
| toMap includes all fields | `toMap()` が全フィールドを正しく変換する |
| fromMap restores Memo correctly | `fromMap()` でMemoが正しく復元される |
| insert and getAll returns the memo | insertしたメモをgetAllで取得できる |
| update changes memo fields | updateで変更が反映される |
| delete removes the memo | deleteでメモが削除される |
| getAll returns memos sorted by createdAt descending | getAllが降順でソートされる |
| multiple inserts accumulate | 複数insertで件数が積み上がる |

## 既知の制約

- `DatabaseService.open()` を呼び出す前に他のメソッドを呼ぶと `null` 参照エラーになる。呼び出し側で `open()` を先に `await` すること。
- `widget_test.dart` はFlutterデフォルトのカウンターアプリ向けテストであり、このプロジェクトでは実装前から失敗している（本Issueとは無関係）。
