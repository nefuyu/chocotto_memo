import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/services/settings_service.dart';

/// 保存成否を外部から制御できるFakeSettingsService。
class ControllableSettingsService implements SettingsService {
  AppSettings? lastSaved;
  Exception? _nextError;
  int saveCallCount = 0;

  void setNextSaveError(Exception e) => _nextError = e;

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {
    saveCallCount++;
    if (_nextError != null) {
      final err = _nextError!;
      _nextError = null;
      throw err;
    }
    lastSaved = settings;
  }
}

void main() {
  group('SettingsNotifier プレビュー更新', () {
    test('updateThemePreviewはsettingsを更新するがsavedSettingsは変わらない', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);

      expect(notifier.settings.theme, AppTheme.dark);
      expect(notifier.savedSettings.theme, AppTheme.system); // 保存済みは変わらない
    });

    test('updateFontSizePreviewはsettingsを更新するがsavedSettingsは変わらない', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      notifier.updateFontSizePreview(AppFontSize.large);

      expect(notifier.settings.fontSize, AppFontSize.large);
      expect(notifier.savedSettings.fontSize, AppFontSize.medium); // 保存済みは変わらない
    });

    test('複数プレビュー更新は両方反映される', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      notifier.updateFontSizePreview(AppFontSize.large);

      expect(notifier.settings.theme, AppTheme.dark);
      expect(notifier.settings.fontSize, AppFontSize.large);
    });
  });

  group('SettingsNotifier 保存', () {
    test('save()成功時にsavedSettingsがpreviewと同じになる', () async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save();

      expect(notifier.savedSettings.theme, AppTheme.dark);
      expect(notifier.settings.theme, AppTheme.dark);
    });

    test('save()成功時にsaveErrorはnull', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save();

      expect(notifier.saveError, isNull);
    });

    test('save()失敗時にsaveErrorがセットされる', () async {
      final service = ControllableSettingsService();
      service.setNextSaveError(Exception('保存失敗'));
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save();

      expect(notifier.saveError, isNotNull);
    });

    test('save()失敗時にpreviewSettingsがsavedSettingsに巻き戻る', () async {
      final service = ControllableSettingsService();
      service.setNextSaveError(Exception('保存失敗'));
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save(); // 失敗

      expect(notifier.settings.theme, AppTheme.system); // savedSettings(system)に巻き戻る
      expect(notifier.savedSettings.theme, AppTheme.system);
    });

    test('save()失敗後に再度save()が成功するとsaveErrorがクリアされる', () async {
      final service = ControllableSettingsService();
      service.setNextSaveError(Exception('保存失敗'));
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save(); // 失敗
      expect(notifier.saveError, isNotNull);

      // 巻き戻り後に再操作して再保存
      notifier.updateFontSizePreview(AppFontSize.large);
      await notifier.save(); // 成功

      expect(notifier.saveError, isNull);
    });

    test('save()開始直後はisSavingがtrue', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      final future = notifier.save();
      expect(notifier.isSaving, isTrue);
      await future;
    });

    test('save()完了後はisSavingがfalse', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      await notifier.save();

      expect(notifier.isSaving, isFalse);
    });

    test('save()失敗後もisSavingがfalseに戻る', () async {
      final service = ControllableSettingsService();
      service.setNextSaveError(Exception('保存失敗'));
      final notifier = SettingsNotifier(service);
      await notifier.load();

      await notifier.save();

      expect(notifier.isSaving, isFalse);
    });

    test('初期状態ではsaveErrorはnull', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();
      expect(notifier.saveError, isNull);
    });
  });

  group('SettingsNotifier 排他制御', () {
    test('save()中に再度save()を呼んでも2重保存されない', () async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();

      final f1 = notifier.save();
      final f2 = notifier.save(); // isSaving==trueのためスキップ
      await Future.wait([f1, f2]);

      expect(service.saveCallCount, 1); // 1回しか保存されない
    });
  });

  group('SettingsNotifier discardPreview', () {
    test('discardPreviewでpreviewがsavedSettingsに戻る', () async {
      final notifier = SettingsNotifier(ControllableSettingsService());
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      notifier.updateFontSizePreview(AppFontSize.large);
      notifier.discardPreview();

      expect(notifier.settings.theme, AppTheme.system);
      expect(notifier.settings.fontSize, AppFontSize.medium);
    });

    test('discardPreviewでsaveErrorもクリアされる', () async {
      final service = ControllableSettingsService();
      service.setNextSaveError(Exception('保存失敗'));
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save(); // 失敗してsaveErrorがセット
      expect(notifier.saveError, isNotNull);

      notifier.discardPreview();

      expect(notifier.saveError, isNull);
    });

    test('discardPreview後もsave済み設定が維持されている', () async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();

      notifier.updateThemePreview(AppTheme.dark);
      await notifier.save(); // ダークを保存
      expect(notifier.savedSettings.theme, AppTheme.dark);

      notifier.updateThemePreview(AppTheme.light); // ライトをプレビュー
      notifier.discardPreview(); // 破棄

      expect(notifier.settings.theme, AppTheme.dark); // 保存済みダークに戻る
    });
  });
}
