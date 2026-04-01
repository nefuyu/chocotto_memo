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

  Future<void> _onLongPress(BuildContext context, Memo memo, Offset tapPosition) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx,
        tapPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'delete', child: Text('削除')),
      ],
    );

    if (selected == 'delete' && context.mounted) {
      await _confirmDelete(context, memo);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Memo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.db.delete(memo.id!);
      await _loadMemos();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
        await _loadMemos();
      }
    }
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
                return GestureDetector(
                  onLongPressStart: (details) =>
                      _onLongPress(context, memo, details.globalPosition),
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
