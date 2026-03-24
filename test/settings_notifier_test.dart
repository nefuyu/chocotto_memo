import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/services/settings_service.dart';

/// 呼び出しごとに異なる遅延でsaveをシミュレートするFakeSettingsService。
/// delays[0]が1回目のsave遅延、delays[1]が2回目のsave遅延。
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

void main() {
  group('SettingsNotifier 並行書き込みの直列化', () {
    test('1回目saveが遅く2回目saveが速い場合でも最後のスナップショットは最新状態を持つ', () async {
      // 1回目: 30ms (遅い), 2回目: 5ms (速い)
      // 直列化なしだと2回目が先に完了し、後から1回目が完了して古い値で上書きされる
      final service = DelayedSettingsService([
        const Duration(milliseconds: 30),
        const Duration(milliseconds: 5),
      ]);
      final notifier = SettingsNotifier(service);
      await notifier.load();

      // awaitせずに連続呼び出し（RadioのonChangedと同じ状況）
      final f1 = notifier.updateTheme(AppTheme.dark);
      final f2 = notifier.updateFontSize(AppFontSize.large);
      await Future.wait([f1, f2]);

      // 最後に保存されたスナップショットは最新の状態（dark + large）であること
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
}
