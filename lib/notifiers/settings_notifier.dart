import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings = const AppSettings();
  Future<void> _pendingSave = Future.value();
  String? _saveError;

  SettingsNotifier(this._service);

  AppSettings get settings => _settings;
  String? get saveError => _saveError;

  Future<void> load() async {
    _settings = await _service.load();
    notifyListeners();
  }

  Future<void> updateTheme(AppTheme theme) async {
    _settings = AppSettings(theme: theme, fontSize: _settings.fontSize);
    notifyListeners();
    await _queueSave();
  }

  Future<void> updateFontSize(AppFontSize fontSize) async {
    _settings = AppSettings(theme: _settings.theme, fontSize: fontSize);
    notifyListeners();
    await _queueSave();
  }

  /// 保存を直列化してキューに積む。
  /// save失敗時は_pendingSaveを正常完了状態に戻し、次回保存を可能にする。
  Future<void> _queueSave() {
    _pendingSave = _pendingSave
        .catchError((_) {}) // 前回のエラーがあっても次の保存をブロックしない
        .then((_) async {
          try {
            await _service.save(_settings);
            if (_saveError != null) {
              _saveError = null;
              notifyListeners();
            }
          } catch (_) {
            _saveError = '設定の保存に失敗しました';
            notifyListeners();
          }
        });
    return _pendingSave;
  }
}
