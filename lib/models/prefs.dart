// 1. Add to Prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

const String TIMER_COLOR = "timerColor";
const int DEFAULT_TIMER_COLOR = 0xFF2196F3; // Blue

class Prefs {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  // Existing... then add:
  static int get timerColor =>
      instance.getInt(TIMER_COLOR) ?? DEFAULT_TIMER_COLOR;
  static set timerColor(int value) => instance.setInt(TIMER_COLOR, value);
}
