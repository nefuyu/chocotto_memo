import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/screens/settings_screen.dart';
import 'package:chocotto_memo/services/settings_service.dart';

/// Completerで保存完了タイミングを制御できるFakeSettingsService。
class ControllableSettingsService implements SettingsService {
  Completer<void>? _completer;
  bool shouldFail = false;

  void completeWithError() => _completer?.completeError(Exception('保存失敗'));
  void completeSuccess() => _completer?.complete();

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) {
    _completer = Completer<void>();
    return _completer!.future;
  }
}

/// 常に保存失敗するFakeSettingsService。
class AlwaysFailingSettingsService implements SettingsService {
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

  group('SettingsScreen 表示', () {
    testWidgets('設定画面のタイトルが表示される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('テーマ切り替えのUIが存在する', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      expect(find.text('テーマ'), findsOneWidget);
      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('システム'), findsOneWidget);
    });

    testWidgets('フォントサイズ切り替えのUIが存在する', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      expect(find.text('フォントサイズ'), findsOneWidget);
      expect(find.text('小'), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
      expect(find.text('大'), findsOneWidget);
    });

    testWidgets('保存ボタンが表示される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('デフォルトではシステムテーマが選択されている', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      final radio = tester.widgetList<RadioListTile<AppTheme>>(
        find.byType(RadioListTile<AppTheme>),
      ).firstWhere((r) => r.value == AppTheme.system);
      expect(radio.groupValue, AppTheme.system);
    });

    testWidgets('デフォルトでは中フォントが選択されている', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));
      final radio = tester.widgetList<RadioListTile<AppFontSize>>(
        find.byType(RadioListTile<AppFontSize>),
      ).firstWhere((r) => r.value == AppFontSize.medium);
      expect(radio.groupValue, AppFontSize.medium);
    });
  });

  group('SettingsScreen プレビュー動作', () {
    testWidgets('ラジオ変更でプレビューが即時反映される（保存前）', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('ダーク'));
      await tester.pump();

      expect(notifier.settings.theme, AppTheme.dark);
      expect(notifier.savedSettings.theme, AppTheme.system); // 保存済みはまだsystem
    });

    testWidgets('フォントサイズのラジオ変更でプレビューが即時反映される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('大'));
      await tester.pump();

      expect(notifier.settings.fontSize, AppFontSize.large);
      expect(notifier.savedSettings.fontSize, AppFontSize.medium); // 保存済みはまだmedium
    });
  });

  group('SettingsScreen 保存ボタン', () {
    testWidgets('保存ボタンをタップするとsave()が実行されsavedSettingsが更新される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('ダーク'));
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(notifier.savedSettings.theme, AppTheme.dark);
    });

    testWidgets('保存中は保存ボタンが無効になる', (tester) async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('保存'));
      await tester.pump(); // save開始、まだ完了していない

      // 保存中はボタンが無効（onPressedがnull）
      final button = tester.widget<TextButton>(find.widgetWithText(TextButton, '保存'));
      expect(button.onPressed, isNull);

      service.completeSuccess();
      await tester.pumpAndSettle();
    });

    testWidgets('保存完了後は保存ボタンが再び有効になる', (tester) async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('保存'));
      await tester.pump();

      service.completeSuccess();
      await tester.pumpAndSettle();

      final button = tester.widget<TextButton>(find.widgetWithText(TextButton, '保存'));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('保存中はラジオボタンが無効になる', (tester) async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('保存'));
      await tester.pump(); // save開始

      final radios = tester.widgetList<RadioListTile<AppTheme>>(
        find.byType(RadioListTile<AppTheme>),
      );
      for (final radio in radios) {
        expect(radio.onChanged, isNull);
      }

      service.completeSuccess();
      await tester.pumpAndSettle();
    });
  });

  group('SettingsScreen 保存エラー', () {
    testWidgets('save失敗時にSnackBarが表示される', (tester) async {
      final notifier = SettingsNotifier(AlwaysFailingSettingsService());
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('save失敗後にプレビューが保存済み設定に巻き戻る', (tester) async {
      final notifier = SettingsNotifier(AlwaysFailingSettingsService());
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      await tester.tap(find.text('ダーク'));
      await tester.pump();
      expect(notifier.settings.theme, AppTheme.dark); // プレビューはダーク

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle(); // 失敗→巻き戻り

      expect(notifier.settings.theme, AppTheme.system); // systemに戻る
    });

    testWidgets('save失敗後の次の保存でSnackBarが誤って再表示されない', (tester) async {
      final service = ControllableSettingsService();
      final notifier = SettingsNotifier(service);
      await notifier.load();
      await tester.pumpWidget(MaterialApp(home: SettingsScreen(notifier: notifier)));

      // 1回目保存 → 失敗 → SnackBar表示
      await tester.tap(find.text('保存'));
      await tester.pump();
      service.completeWithError();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      // SnackBarが消えるまで時間を進める
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 再保存開始 → save完了前の時点でSnackBarが誤表示されないこと
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      service.completeSuccess();
      await tester.pumpAndSettle();
    });
  });

  group('SettingsScreen 離脱時プレビュー破棄', () {
    testWidgets('保存せずに画面を離脱するとプレビューがsavedSettingsに戻る', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(notifier: notifier),
                    ),
                  ),
                  child: const Text('設定へ'),
                ),
              ),
            ),
          ),
        ),
      ));

      // 設定画面へ遷移
      await tester.tap(find.text('設定へ'));
      await tester.pumpAndSettle();

      // プレビュー変更
      await tester.tap(find.text('ダーク'));
      await tester.pump();
      expect(notifier.settings.theme, AppTheme.dark);

      // 保存せずに戻る
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // プレビューが破棄されてsavedSettings(system)に戻る
      expect(notifier.settings.theme, AppTheme.system);
    });

    testWidgets('保存してから画面を離脱してもsavedSettingsは維持される', (tester) async {
      final notifier = await createNotifier();
      await tester.pumpWidget(MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(notifier: notifier),
                    ),
                  ),
                  child: const Text('設定へ'),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('設定へ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ダーク'));
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(notifier.savedSettings.theme, AppTheme.dark);

      // 保存後に戻る
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // 保存済み設定はダークのまま
      expect(notifier.settings.theme, AppTheme.dark);
      expect(notifier.savedSettings.theme, AppTheme.dark);
    });
  });
}
