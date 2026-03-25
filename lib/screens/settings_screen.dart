import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../notifiers/settings_notifier.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsNotifier notifier;

  const SettingsScreen({super.key, required this.notifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    widget.notifier.discardPreview(); // 保存せず離脱した場合はプレビューを破棄
    super.dispose();
  }

  void _onNotifierChanged() {
    if (!mounted) return;
    final error = widget.notifier.saveError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final settings = widget.notifier.settings;
        final isSaving = widget.notifier.isSaving;
        return Scaffold(
          appBar: AppBar(
            title: const Text('設定'),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => widget.notifier.save(),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ],
          ),
          body: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('テーマ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioListTile<AppTheme>(
                title: const Text('システム'),
                value: AppTheme.system,
                groupValue: settings.theme,
                onChanged: isSaving ? null : (v) => widget.notifier.updateThemePreview(v!),
              ),
              RadioListTile<AppTheme>(
                title: const Text('ライト'),
                value: AppTheme.light,
                groupValue: settings.theme,
                onChanged: isSaving ? null : (v) => widget.notifier.updateThemePreview(v!),
              ),
              RadioListTile<AppTheme>(
                title: const Text('ダーク'),
                value: AppTheme.dark,
                groupValue: settings.theme,
                onChanged: isSaving ? null : (v) => widget.notifier.updateThemePreview(v!),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('フォントサイズ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioListTile<AppFontSize>(
                title: const Text('小'),
                value: AppFontSize.small,
                groupValue: settings.fontSize,
                onChanged: isSaving ? null : (v) => widget.notifier.updateFontSizePreview(v!),
              ),
              RadioListTile<AppFontSize>(
                title: const Text('中'),
                value: AppFontSize.medium,
                groupValue: settings.fontSize,
                onChanged: isSaving ? null : (v) => widget.notifier.updateFontSizePreview(v!),
              ),
              RadioListTile<AppFontSize>(
                title: const Text('大'),
                value: AppFontSize.large,
                groupValue: settings.fontSize,
                onChanged: isSaving ? null : (v) => widget.notifier.updateFontSizePreview(v!),
              ),
            ],
          ),
        );
      },
    );
  }
}
