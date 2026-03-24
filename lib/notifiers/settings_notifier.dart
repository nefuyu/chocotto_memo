import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings = const AppSettings();
  Future<void> _pendingSave = Future.value();

  SettingsNotifier(this._service);

  AppSettings get settings => _settings;

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

  /// 前の保存完了後に最新の _settings を保存するようキューに積む。
  Future<void> _queueSave() {
    _pendingSave = _pendingSave.whenComplete(() => _service.save(_settings));
    return _pendingSave;
  }
}
