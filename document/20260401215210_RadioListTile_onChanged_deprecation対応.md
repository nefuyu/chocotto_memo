# RadioListTile.onChanged deprecation対応

## Issue概要
Flutterの新バージョンで `RadioListTile.onChanged` および `groupValue` が deprecated となったため、代替APIへ移行した。

## 実装方針
- 各 `RadioListTile` に直接設定していた `onChanged`・`groupValue` を、親ウィジェットである `RadioGroup` に集約する
- 保存中の無効化を `onChanged: null` から `enabled: !isSaving` に変更する
- テストコードも同様の修正を適用する

## 変更ファイル

### `lib/screens/settings_screen.dart`
- `RadioListTile` ごとに設定していた `groupValue` と `onChanged` を削除
- `RadioGroup<AppTheme>` / `RadioGroup<AppFontSize>` の `onChanged` にコールバックを集約
- `RadioListTile` には `enabled: !isSaving` を設定して保存中の操作を無効化

### `test/settings_screen_test.dart`
- `radio.onChanged` チェックを `radio.enabled` チェックに変更
- 保存中の保存ボタン確認を `find.widgetWithText(TextButton, '保存')` から `find.byType(TextButton)` に変更（保存中はボタンのchildがCircularProgressIndicatorになるため）
- Navigator取得を `tester.state(find.byType(Navigator))` から `GlobalKey<NavigatorState>` を使った取得に変更（MaterialApp内部のNavigatorと競合するため）

## テスト方針
既存の18テストがすべて通過することを確認済み。新規テストの追加は不要（既存テストが動作確認を兼ねる）。

## 既知の制約
なし
