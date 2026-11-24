import 'package:material_ui/material_ui.dart';

class KashkoolTheme {
  static const Color background = Color(0xFF060913);
  static const Color surface = Color(0xFF0B1021);
  static const Color accent = Color(0xFF00F5D4);
  static const Color solarGold = Color(0xFFFFD700);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      useMaterial3: true,
    );
  }
}

/// App-wide brand colors used by the Pricing Calculator and billing UI.
class AppTheme {
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFF7B2FFF);
  static const Color neonPink = Color(0xFFFF2D95);
}
