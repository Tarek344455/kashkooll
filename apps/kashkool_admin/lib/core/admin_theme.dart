import 'package:material_ui/material_ui.dart';

class AdminTheme {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color commandGold = Color(0xFFFFD700);
  static const Color crisisCrimson = Color(0xFFDC143C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: commandGold,
      colorScheme: const ColorScheme.dark(
        primary: commandGold,
        error: crisisCrimson,
        surface: surface,
      ),
      useMaterial3: true,
    );
  }
}
