import 'package:flutter/material.dart';
import 'constants.dart';

/// Tema "retro minimalism": kertas hangat, tinta pekat, garis tipis,
/// tipografi monospace dengan letter-spacing ala terminal/cetakan lawas.
ThemeData buildRetroTheme() {
  const base = TextStyle(
    fontFamily: 'monospace',
    color: RetroColor.ink,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  const thinBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: RetroColor.ink, width: 1),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: RetroColor.cream,
    fontFamily: 'monospace',
    colorScheme: const ColorScheme.light(
      primary: RetroColor.ink,
      secondary: RetroColor.yellow400,
      surface: RetroColor.surface,
      onSurface: RetroColor.ink,
    ),
    dividerTheme: const DividerThemeData(
      color: RetroColor.ink,
      thickness: 1,
      space: 20,
    ),
    textTheme: TextTheme(
      bodyLarge: base.copyWith(fontSize: 14),
      bodyMedium: base.copyWith(fontSize: 12),
      bodySmall: base.copyWith(fontSize: 10, color: RetroColor.gray500),
      titleLarge: base.copyWith(
          fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2),
      titleMedium: base.copyWith(
          fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      titleSmall: base.copyWith(
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
      labelLarge: base.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(),
      side: const BorderSide(color: RetroColor.ink, width: 1.2),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RetroColor.ink
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(RetroColor.cream),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RetroColor.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: thinBorder,
      enabledBorder: thinBorder,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: RetroColor.ink, width: 1.6),
      ),
      labelStyle: base.copyWith(fontSize: 11),
      hintStyle: base.copyWith(fontSize: 12, color: RetroColor.gray400),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: RetroColor.surface,
      headerBackgroundColor: RetroColor.ink,
      headerForegroundColor: RetroColor.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: RetroColor.ink, width: 1),
      ),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: RetroColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: RetroColor.ink, width: 1),
      ),
    ),
  );
}
