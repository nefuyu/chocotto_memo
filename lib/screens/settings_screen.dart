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
    super.dispose();
  }

  void _onNotifierChanged() {
    if (widget.notifier.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.notifier.saveError!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          final settings = widget.notifier.settings;
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('テーマ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              RadioListTile<AppTheme>(
                title: const Text('システム'),
                value: AppTheme.system,
                groupValue: settings.theme,
                onChanged: (v) => widget.notifier.updateTheme(v!),
              ),
              RadioListTile<AppTheme>(
                title: const Text('ライト'),
                value: AppTheme.light,
                groupValue: settings.theme,
                onChanged: (v) => widget.notifier.updateTheme(v!),
              ),
              RadioListTile<AppTheme>(
                title: const Text('ダーク'),
                value: AppTheme.dark,
                groupValue: settings.theme,
                onChanged: (v) => widget.notifier.updateTheme(v!),
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
                onChanged: (v) => widget.notifier.updateFontSize(v!),
              ),
              RadioListTile<AppFontSize>(
                title: const Text('中'),
                value: AppFontSize.medium,
                groupValue: settings.fontSize,
                onChanged: (v) => widget.notifier.updateFontSize(v!),
              ),
              RadioListTile<AppFontSize>(
                title: const Text('大'),
                value: AppFontSize.large,
                groupValue: settings.fontSize,
                onChanged: (v) => widget.notifier.updateFontSize(v!),
              ),
            ],
          );
        },
      ),
    );
  }
}
