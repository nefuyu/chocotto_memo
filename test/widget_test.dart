import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chocotto_memo/main.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
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
}
