import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';

class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode => Prefs.darkThemeOn;

  void toggleTheme(bool isOn) {
    Prefs.darkThemeOn = isOn;
    notifyListeners();
  }

  ThemeMode get currentTheme => isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
