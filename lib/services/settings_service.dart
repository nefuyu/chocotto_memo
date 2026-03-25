import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _keySettings = 'settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return AppSettings(
          theme: _parseEnum(AppTheme.values, map['theme'] as int?, AppTheme.system),
          fontSize: _parseEnum(AppFontSize.values, map['fontSize'] as int?, AppFontSize.medium),
        );
      } catch (_) {}
    }
    return const AppSettings(theme: AppTheme.system, fontSize: AppFontSize.medium);
  }

  T _parseEnum<T>(List<T> values, int? index, T fallback) {
    if (index == null || index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({'theme': settings.theme.index, 'fontSize': settings.fontSize.index});
    final ok = await prefs.setString(_keySettings, json);
    if (!ok) {
      throw Exception('設定の書き込みに失敗しました');
    }
  }
}
