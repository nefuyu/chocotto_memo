import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/services/settings_service.dart';

/// 呼び出しごとに異なる遅延でsaveをシミュレートするFakeSettingsService。
class DelayedSettingsService implements SettingsService {
  final List<AppSettings> savedSnapshots = [];
  final List<Duration> delays;
  int _callCount = 0;

  DelayedSettingsService(this.delays);

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {
    final delay =
        _callCount < delays.length ? delays[_callCount] : Duration.zero;
    _callCount++;
    await Future.delayed(delay);
    savedSnapshots.add(settings);
  }
}

/// saveが指定回数だけ失敗し、その後は成功するFakeSettingsService。
class FailingSettingsService implements SettingsService {
  final List<AppSettings> savedSnapshots = [];
  int failCount;

  FailingSettingsService({this.failCount = 1});

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {
    if (failCount > 0) {
      failCount--;
      throw Exception('保存失敗');
    }
    savedSnapshots.add(settings);
  }
}

void main() {
  group('SettingsNotifier 並行書き込みの直列化', () {
    test('1回目saveが遅く2回目saveが速い場合でも最後のスナップショットは最新状態を持つ', () async {
      final service = DelayedSettingsService([
        const Duration(milliseconds: 30),
        const Duration(milliseconds: 5),
      ]);
      final notifier = SettingsNotifier(service);
      await notifier.load();

      final f1 = notifier.updateTheme(AppTheme.dark);
      final f2 = notifier.updateFontSize(AppFontSize.large);
      await Future.wait([f1, f2]);

      expect(service.savedSnapshots.last.theme, AppTheme.dark);
      expect(service.savedSnapshots.last.fontSize, AppFontSize.large);
    });

    test('連続更新後のnotifier状態は両方の変更が反映されている', () async {
      final service = DelayedSettingsService([
        const Duration(milliseconds: 20),
        const Duration(milliseconds: 5),
      ]);
      final notifier = SettingsNotifier(service);
      await notifier.load();

      final f1 = notifier.updateTheme(AppTheme.dark);
      final f2 = notifier.updateFontSize(AppFontSize.large);
      await Future.wait([f1, f2]);

      expect(notifier.settings.theme, AppTheme.dark);
      expect(notifier.settings.fontSize, AppFontSize.large);
    });
  });

  group('SettingsNotifier エラー回復', () {
    test('初期状態ではsaveErrorはnull', () async {
      final notifier = SettingsNotifier(FailingSettingsService(failCount: 0));
      await notifier.load();
      expect(notifier.saveError, isNull);
    });

    test('save失敗時にsaveErrorがセットされる', () async {
      final notifier = SettingsNotifier(FailingSettingsService(failCount: 1));
      await notifier.load();

      await notifier.updateTheme(AppTheme.dark);

      expect(notifier.saveError, isNotNull);
    });

    test('save失敗後も次の更新操作は実行できる（キューがリセットされる）', () async {
      // 1回目は失敗、2回目は成功
      final service = FailingSettingsService(failCount: 1);
      final notifier = SettingsNotifier(service);
      await notifier.load();

      await notifier.updateTheme(AppTheme.dark); // 失敗
      await notifier.updateFontSize(AppFontSize.large); // 成功するはず

      expect(service.savedSnapshots, isNotEmpty);
      expect(service.savedSnapshots.last.fontSize, AppFontSize.large);
    });

    test('save成功時にsaveErrorがクリアされる', () async {
      final service = FailingSettingsService(failCount: 1);
      final notifier = SettingsNotifier(service);
      await notifier.load();

      await notifier.updateTheme(AppTheme.dark); // 失敗 → saveError セット
      expect(notifier.saveError, isNotNull);

      await notifier.updateFontSize(AppFontSize.large); // 成功 → saveError クリア
      expect(notifier.saveError, isNull);
    });
  });
}
