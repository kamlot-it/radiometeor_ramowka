import 'package:flutter/material.dart';

class ThemeConfig {
  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF777777);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color white = Colors.white;

  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryOrange),
        useMaterial3: true,
      );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
