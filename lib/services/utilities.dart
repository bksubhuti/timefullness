import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';

String cleanTime(String time) {
  return time
      .replaceAll(RegExp(r'[\u202F\u00A0]'), ' ') // Convert NBSP to space
      .replaceFirstMapped(
        RegExp(r'^(\d):'),
        (m) => '0${m[1]}:',
      ) // Add leading zero
      .trim();
}

Color lighten(Color color, [double amount = 0.45]) {
  final hsl = HSLColor.fromColor(color);
  final lighter = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return lighter.toColor();
}

Color getAdjustedColor(BuildContext context) {
  final rawColor = Color(Prefs.timerColor);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? lighten(rawColor, 0.45) : rawColor;
}
