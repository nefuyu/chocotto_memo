import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _keyTheme = 'theme';
  static const _keyFontSize = 'fontSize';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme) ?? AppTheme.system.index;
    final fontSizeIndex = prefs.getInt(_keyFontSize) ?? AppFontSize.medium.index;
    return AppSettings(
      theme: AppTheme.values[themeIndex],
      fontSize: AppFontSize.values[fontSizeIndex],
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, settings.theme.index);
    await prefs.setInt(_keyFontSize, settings.fontSize.index);
  }
}
