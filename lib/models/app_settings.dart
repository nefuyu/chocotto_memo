import 'package:flutter/material.dart';

enum AppTheme { light, dark, system }

enum AppFontSize { small, medium, large }

class AppSettings {
  final AppTheme theme;
  final AppFontSize fontSize;

  const AppSettings({
    this.theme = AppTheme.system,
    this.fontSize = AppFontSize.medium,
  });

  ThemeMode get themeMode {
    switch (theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  double get fontScale {
    switch (fontSize) {
      case AppFontSize.small:
        return 0.85;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.2;
    }
  }
}
