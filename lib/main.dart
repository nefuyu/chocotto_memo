import 'package:flutter/material.dart';
import 'package:chocotto_memo/notifiers/settings_notifier.dart';
import 'package:chocotto_memo/screens/home_screen.dart';
import 'package:chocotto_memo/services/database_service.dart';
import 'package:chocotto_memo/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.open();
  final notifier = SettingsNotifier(SettingsService());
  await notifier.load();
  runApp(MyApp(db: db, settingsNotifier: notifier));
}

class MyApp extends StatelessWidget {
  final DatabaseService db;
  final SettingsNotifier settingsNotifier;

  const MyApp({super.key, required this.db, required this.settingsNotifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsNotifier,
      builder: (context, _) {
        final settings = settingsNotifier.settings;
        return MaterialApp(
          title: 'Chocotto Memo',
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontScale),
            ),
            child: child!,
          ),
          home: HomeScreen(db: db, settingsNotifier: settingsNotifier),
        );
      },
    );
  }
}
