import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B1E2B),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
