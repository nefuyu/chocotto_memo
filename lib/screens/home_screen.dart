import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../notifiers/settings_notifier.dart';
import '../services/database_service.dart';
import 'memo_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService db;
  final SettingsNotifier settingsNotifier;

  const HomeScreen({super.key, required this.db, required this.settingsNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Memo> _memos = [];

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    final memos = await widget.db.getAll();
    setState(() {
      _memos = memos;
    });
  }

  Future<void> _deleteMemo(Memo memo) async {
    setState(() {
      _memos.removeWhere((m) => m.id == memo.id);
    });
    await widget.db.delete(memo.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('メモを削除しました'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            await widget.db.insert(Memo(
              title: memo.title,
              content: memo.content,
              emoji: memo.emoji,
              createdAt: memo.createdAt,
              updatedAt: memo.updatedAt,
            ));
            _loadMemos();
          },
        ),
      ),
    );
  }

  Future<void> _navigateToEdit({Memo? memo}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoEditScreen(db: widget.db, memo: memo),
      ),
    );
    _loadMemos();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(notifier: widget.settingsNotifier),
                ),
              );
            },
          ),
        ],
      ),
      body: _memos.isEmpty
          ? const Center(
              child: Text('メモがありません。右下のボタンから作成しましょう'),
            )
          : ListView.builder(
              itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                return Dismissible(
                  key: Key('memo_${memo.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteMemo(memo),
                  child: ListTile(
                    leading: Text(
                      memo.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(memo.title),
                    subtitle: Text(
                      memo.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(_formatDate(memo.createdAt)),
                    onTap: () => _navigateToEdit(memo: memo),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
