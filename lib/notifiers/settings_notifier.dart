import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _savedSettings = const AppSettings();
  AppSettings _previewSettings = const AppSettings();
  bool _isSaving = false;
  String? _saveError;

  SettingsNotifier(this._service);

  /// UIが表示する設定（プレビュー込み）
  AppSettings get settings => _previewSettings;

  /// 最後に保存成功した設定
  AppSettings get savedSettings => _savedSettings;

  /// 保存中かどうか（保存ボタンの制御に使用）
  bool get isSaving => _isSaving;

  /// 保存エラーメッセージ（nullならエラーなし）
  String? get saveError => _saveError;

  Future<void> load() async {
    _savedSettings = await _service.load();
    _previewSettings = _savedSettings;
    notifyListeners();
  }

  /// テーマをプレビュー更新（保存はしない）
  void updateThemePreview(AppTheme theme) {
    _previewSettings = AppSettings(theme: theme, fontSize: _previewSettings.fontSize);
    notifyListeners();
  }

  /// フォントサイズをプレビュー更新（保存はしない）
  void updateFontSizePreview(AppFontSize fontSize) {
    _previewSettings = AppSettings(theme: _previewSettings.theme, fontSize: fontSize);
    notifyListeners();
  }

  /// プレビューを破棄し、保存済み設定に戻す（画面離脱時に呼ぶ）
  void discardPreview() {
    _previewSettings = _savedSettings;
    _saveError = null;
    notifyListeners();
  }

  /// 現在のプレビュー設定を保存する
  Future<void> save() async {
    if (_isSaving) return; // 排他制御
    _isSaving = true;
    _saveError = null;
    notifyListeners();

    final snapshot = _previewSettings;
    try {
      await _service.save(snapshot);
      _savedSettings = snapshot;
    } catch (_) {
      _saveError = '設定の保存に失敗しました';
      _previewSettings = _savedSettings; // プレビューを巻き戻す
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
