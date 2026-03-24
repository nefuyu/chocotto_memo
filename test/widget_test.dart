import 'package:flutter_test/flutter_test.dart';

import 'package:chocotto_memo/main.dart';
import 'fake_database_service.dart';

void main() {
  testWidgets('アプリが起動してホーム画面が表示される', (WidgetTester tester) async {
    final db = FakeDatabaseService();
    await tester.pumpWidget(MyApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text('メモ一覧'), findsOneWidget);
  });
}
