import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings = const AppSettings();

  SettingsNotifier(this._service);

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _service.load();
    notifyListeners();
  }

  Future<void> updateTheme(AppTheme theme) async {
    _settings = AppSettings(theme: theme, fontSize: _settings.fontSize);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> updateFontSize(AppFontSize fontSize) async {
    _settings = AppSettings(theme: _settings.theme, fontSize: fontSize);
    await _service.save(_settings);
    notifyListeners();
  }
}
