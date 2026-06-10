import 'package:flutter/material.dart';
import 'constants.dart';

ThemeData buildRetroTheme() {
  const base = TextStyle(
    fontFamily: 'monospace',
    color: Colors.black,
    fontWeight: FontWeight.w700,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: RetroColor.cream,
    fontFamily: 'monospace',
    colorScheme: const ColorScheme.light(
      primary: RetroColor.yellow400,
      secondary: RetroColor.purple400,
      surface: Colors.white,
    ),
    textTheme: TextTheme(
      bodyLarge: base.copyWith(fontSize: 14),
      bodyMedium: base.copyWith(fontSize: 12),
      bodySmall: base.copyWith(fontSize: 10),
      titleLarge: base.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
      titleMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
      titleSmall: base.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
      labelLarge: base.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      labelStyle: base.copyWith(fontSize: 11),
      hintStyle: base.copyWith(fontSize: 12, color: RetroColor.gray400),
    ),
  );
}
