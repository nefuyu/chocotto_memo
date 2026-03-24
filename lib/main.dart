import 'package:flutter/material.dart';
import 'package:chocotto_memo/screens/home_screen.dart';
import 'package:chocotto_memo/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.open();
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final DatabaseService db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chocotto Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(db: db),
    );
  }
}
