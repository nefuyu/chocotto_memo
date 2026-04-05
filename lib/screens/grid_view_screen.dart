import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../models/memo_view.dart';
import '../services/database_service.dart';
import 'memo_edit_screen.dart';

class GridViewScreen extends StatefulWidget {
  final MemoView view;
  final DatabaseService db;

  const GridViewScreen({super.key, required this.view, required this.db});

  @override
  State<GridViewScreen> createState() => _GridViewScreenState();
}

class _GridViewScreenState extends State<GridViewScreen> {
  static const _gridSize = 3;

  Map<int, Memo> _grid = {};

  @override
  void initState() {
    super.initState();
    _loadGrid();
  }

  Future<void> _loadGrid() async {
    try {
      final grid = await widget.db.getGridMemos(widget.view.id);
      if (!mounted) return;
      setState(() => _grid = grid);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メモの読み込みに失敗しました')),
      );
    }
  }

  Future<void> _navigateToEdit(Memo memo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoEditScreen(db: widget.db, memo: memo),
      ),
    );
    _loadGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.view.name)),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _gridSize * _gridSize,
        itemBuilder: (context, index) {
          final memo = _grid[index];
          if (memo != null) {
            return _MemoCell(memo: memo, onTap: () => _navigateToEdit(memo));
          }
          return _EmptyCell(index: index);
        },
      ),
    );
  }
}

class _MemoCell extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;

  const _MemoCell({required this.memo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${memo.title} ${memo.emoji}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(memo.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  memo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  final int index;

  const _EmptyCell({required this.index});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '空のセル',
      child: Container(
        key: ValueKey<String>('grid_cell_$index'),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
