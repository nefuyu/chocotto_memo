# Issue #24: memos テーブルに updated_at カラムを追加

## Issue 概要

`memos` テーブルに `updated_at` カラムを追加し、ソート順を `created_at DESC` から `updated_at DESC` へ変更する。

## 実装方針

- TDD: テスト先行で実装
- DBバージョンを 1 → 2 に上げ、`onUpgrade` で既存レコードに `updated_at = created_at` を設定するマイグレーションを実装
- `DatabaseService.update()` が呼ばれた際、サービス層で `updated_at` を `DateTime.now()` に上書きする

## クラス / 関数構成

### `lib/models/memo.dart`

| 変更点 | 内容 |
|---|---|
| フィールド追加 | `final DateTime updatedAt` |
| コンストラクタ | `required this.updatedAt` を追加 |
| `toMap()` | `'updated_at': updatedAt.toIso8601String()` を追加 |
| `fromMap()` | `updatedAt: DateTime.parse(map['updated_at'])` を追加 |

### `lib/services/database_service.dart`

| 変更点 | 内容 |
|---|---|
| `_dbVersion` | `1` → `2` |
| `onCreate` | `updated_at TEXT NOT NULL` カラムを追加 |
| `onUpgrade` | `ALTER TABLE memos ADD COLUMN updated_at ...` + `UPDATE SET updated_at = created_at` |
| `getAll()` | `orderBy: 'updated_at DESC'` |
| `update()` | `map['updated_at'] = DateTime.now().toIso8601String()` で上書き |

### `lib/screens/memo_edit_screen.dart`

- 新規作成時: `updatedAt: now`（`createdAt` と同じ値）
- 編集時: `updatedAt: widget.memo!.updatedAt`（サービス側で上書きされる）

### `test/fake_database_service.dart`

- `insert()`: `updatedAt` を保存
- `getAll()`: `updatedAt DESC` でソート
- `update()`: `updatedAt = DateTime.now()` で上書き

## テスト方針

### `test/database_service_test.dart`

| テスト | 内容 |
|---|---|
| `toMap includes all fields` | `updated_at` が含まれることを確認 |
| `fromMap restores Memo correctly` | `updatedAt` が正しく復元されることを確認 |
| `update changes memo fields and sets updatedAt to now` | 更新後に `updatedAt` が現在時刻に更新されることを確認 |
| `getAll returns memos sorted by updatedAt descending` | ソート順が `updated_at DESC` であることを確認 |

既存テストも `Memo` コンストラクタの `updatedAt` 引数追加に合わせて更新。

## 既知の制約

- インメモリDBを使ったテストのため、`onUpgrade` マイグレーションのテストは省略（新規スキーマで動作確認）
- `home_screen.dart` の表示日付は引き続き `createdAt` を表示（表示変更は別Issue対応）
