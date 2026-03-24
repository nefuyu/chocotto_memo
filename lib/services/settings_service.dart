import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _keyTheme = 'theme';
  static const _keyFontSize = 'fontSize';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme);
    final fontSizeIndex = prefs.getInt(_keyFontSize);
    return AppSettings(
      theme: _parseEnum(AppTheme.values, themeIndex, AppTheme.system),
      fontSize: _parseEnum(AppFontSize.values, fontSizeIndex, AppFontSize.medium),
    );
  }

  T _parseEnum<T>(List<T> values, int? index, T fallback) {
    if (index == null || index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, settings.theme.index);
    await prefs.setInt(_keyFontSize, settings.fontSize.index);
  }
}
