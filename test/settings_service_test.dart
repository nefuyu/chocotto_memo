import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/services/settings_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService', () {
    test('デフォルト設定が読み込まれる', () async {
      final service = SettingsService();
      final settings = await service.load();
      expect(settings.theme, AppTheme.system);
      expect(settings.fontSize, AppFontSize.medium);
    });

    test('ダークテーマを保存して復元できる', () async {
      final service = SettingsService();
      await service.save(const AppSettings(theme: AppTheme.dark, fontSize: AppFontSize.medium));
      final settings = await service.load();
      expect(settings.theme, AppTheme.dark);
    });

    test('ライトテーマを保存して復元できる', () async {
      final service = SettingsService();
      await service.save(const AppSettings(theme: AppTheme.light, fontSize: AppFontSize.medium));
      final settings = await service.load();
      expect(settings.theme, AppTheme.light);
    });

    test('フォントサイズ(大)を保存して復元できる', () async {
      final service = SettingsService();
      await service.save(const AppSettings(theme: AppTheme.system, fontSize: AppFontSize.large));
      final settings = await service.load();
      expect(settings.fontSize, AppFontSize.large);
    });

    test('フォントサイズ(小)を保存して復元できる', () async {
      final service = SettingsService();
      await service.save(const AppSettings(theme: AppTheme.system, fontSize: AppFontSize.small));
      final settings = await service.load();
      expect(settings.fontSize, AppFontSize.small);
    });
  });
}
