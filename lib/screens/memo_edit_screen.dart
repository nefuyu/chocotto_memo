import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../services/database_service.dart';

class MemoEditScreen extends StatefulWidget {
  final DatabaseService db;
  final Memo? memo;

  const MemoEditScreen({super.key, required this.db, this.memo});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late final TextEditingController _emojiController;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _emojiController = TextEditingController(text: widget.memo?.emoji ?? '📝');
    _titleController = TextEditingController(text: widget.memo?.title ?? '');
    _contentController = TextEditingController(text: widget.memo?.content ?? '');
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final emoji = _emojiController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    try {
      if (widget.memo == null) {
        await widget.db.insert(Memo(
          title: title,
          content: content,
          emoji: emoji.isEmpty ? '📝' : emoji,
          createdAt: DateTime.now(),
        ));
      } else {
        await widget.db.update(Memo(
          id: widget.memo!.id,
          title: title,
          content: content,
          emoji: emoji.isEmpty ? '📝' : emoji,
          createdAt: widget.memo!.createdAt,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.memo == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '新規作成' : '編集'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(labelText: '絵文字'),
              maxLength: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '本文'),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
