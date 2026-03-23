import 'package:flutter/material.dart';
import '../models/memo.dart';

class HomeScreen extends StatelessWidget {
  final List<Memo> memos;

  const HomeScreen({super.key, required this.memos});

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...memos]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ一覧'),
      ),
      body: sorted.isEmpty
          ? const Center(
              child: Text('メモがありません。右下のボタンから作成しましょう'),
            )
          : ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final memo = sorted[index];
                return ListTile(
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: メモ作成画面への遷移
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
