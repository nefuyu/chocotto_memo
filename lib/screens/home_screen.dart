import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../notifiers/settings_notifier.dart';
import '../services/database_service.dart';
import 'memo_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService db;
  final SettingsNotifier settingsNotifier;
  final int perPage;

  const HomeScreen({
    super.key,
    required this.db,
    required this.settingsNotifier,
    this.perPage = 100,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Memo> _memos = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _loadGeneration = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMemos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMemos() async {
    _loadGeneration++;
    final memos = await widget.db.getAll(limit: widget.perPage, offset: 0);
    if (!mounted) return;
    setState(() {
      _memos = memos;
      _hasMore = memos.length == widget.perPage;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final generation = _loadGeneration;
    final memos = await widget.db.getAll(
      limit: widget.perPage,
      offset: _memos.length,
    );
    if (!mounted) return;
    if (generation != _loadGeneration) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _memos.addAll(memos);
      _hasMore = memos.length == widget.perPage;
      _isLoading = false;
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
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final overlaySize = overlay.size;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        overlaySize.width - tapPosition.dx,
        overlaySize.height - tapPosition.dy,
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
              controller: _scrollController,
              itemCount: _memos.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _memos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
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
