import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/screens/settings_screen.dart';
import 'package:chocotto_memo/services/settings_service.dart';

class FailingSettingsService implements SettingsService {
  @override
  Future<AppSettings> load() async => const AppSettings();
  @override
  Future<void> save(AppSettings settings) async => throw Exception('保存失敗');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsNotifier> createNotifier() async {
    final notifier = SettingsNotifier(SettingsService());
    await notifier.load();
    return notifier;
  }

  group('SettingsScreen', () {
    testWidgets('設定画面のタイトルが表示される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('テーマ切り替えのUIが存在する', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      expect(find.text('テーマ'), findsOneWidget);
      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('システム'), findsOneWidget);
    });

    testWidgets('フォントサイズ切り替えのUIが存在する', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      expect(find.text('フォントサイズ'), findsOneWidget);
      expect(find.text('小'), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
      expect(find.text('大'), findsOneWidget);
    });

    testWidgets('テーマをダークに切り替えるとnotifierに反映される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      await tester.tap(find.text('ダーク'));
      await tester.pumpAndSettle();
      expect(notifier.settings.theme, AppTheme.dark);
    });

    testWidgets('フォントサイズを大に切り替えるとnotifierに反映される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      await tester.tap(find.text('大'));
      await tester.pumpAndSettle();
      expect(notifier.settings.fontSize, AppFontSize.large);
    });

    testWidgets('デフォルトではシステムテーマが選択されている', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      // システムのRadioListTileが選択済み(value == groupValue)
      final radio = tester.widgetList<RadioListTile<AppTheme>>(
        find.byType(RadioListTile<AppTheme>),
      ).firstWhere((r) => r.value == AppTheme.system);
      expect(radio.groupValue, AppTheme.system);
    });

    testWidgets('デフォルトでは中フォントが選択されている', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      final radio = tester.widgetList<RadioListTile<AppFontSize>>(
        find.byType(RadioListTile<AppFontSize>),
      ).firstWhere((r) => r.value == AppFontSize.medium);
      expect(radio.groupValue, AppFontSize.medium);
    });

    testWidgets('save失敗時にSnackBarが表示される', (tester) async {
      final notifier = SettingsNotifier(FailingSettingsService());
      await notifier.load();
      await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(notifier: notifier),
      ));
      await tester.tap(find.text('ダーク'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
