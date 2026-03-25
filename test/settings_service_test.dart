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

    test('テーマに範囲外のインデックスが保存されていてもデフォルト(system)にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({'theme': 999});
      final service = SettingsService();
      final settings = await service.load();
      expect(settings.theme, AppTheme.system);
    });

    test('フォントサイズに範囲外のインデックスが保存されていてもデフォルト(medium)にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({'fontSize': 999});
      final service = SettingsService();
      final settings = await service.load();
      expect(settings.fontSize, AppFontSize.medium);
    });

    test('負のインデックスが保存されていてもデフォルトにフォールバックする', () async {
      SharedPreferences.setMockInitialValues({'theme': -1, 'fontSize': -1});
      final service = SettingsService();
      final settings = await service.load();
      expect(settings.theme, AppTheme.system);
      expect(settings.fontSize, AppFontSize.medium);
    });

    test('save()はテーマとフォントサイズを両方正しく書き込む', () async {
      final service = SettingsService();
      // 例外が投げられなければ書き込み成功（setIntがfalseを返した場合は例外になる）
      await expectLater(
        service.save(const AppSettings(theme: AppTheme.dark, fontSize: AppFontSize.large)),
        completes,
      );
      final settings = await service.load();
      expect(settings.theme, AppTheme.dark);
      expect(settings.fontSize, AppFontSize.large);
    });
  });
}
