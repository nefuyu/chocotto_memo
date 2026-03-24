import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/main.dart';
import 'package:chocotto_memo/models/app_settings.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/screens/home_screen.dart';
import 'package:chocotto_memo/services/settings_service.dart';
import 'fake_database_service.dart';

void main() {
  testWidgets('アプリが起動してホーム画面が表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = FakeDatabaseService();
    final notifier = SettingsNotifier(SettingsService());
    await notifier.load();
    await tester.pumpWidget(MyApp(db: db, settingsNotifier: notifier));
    await tester.pumpAndSettle();

    expect(find.text('メモ一覧'), findsOneWidget);
  });

  testWidgets('アプリのフォントスケールはOSのフォントスケールと合成される', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = FakeDatabaseService();
    final notifier = SettingsNotifier(SettingsService());
    await notifier.load();
    await notifier.updateFontSize(AppFontSize.large); // アプリ設定 1.2x

    // OSのフォントを1.5xにシミュレート
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: MyApp(db: db, settingsNotifier: notifier),
      ),
    );
    await tester.pumpAndSettle();

    // HomeScreen内側のMediaQueryのtextScalerが OS(1.5) × アプリ(1.2) = 1.8 になること
    final ctx = tester.element(find.byType(HomeScreen));
    final effectiveScale = MediaQuery.of(ctx).textScaler.scale(1.0);
    expect(effectiveScale, closeTo(1.5 * 1.2, 0.01));
  });
}
