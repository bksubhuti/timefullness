// 1. Add to Prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

const String TIMER_COLOR = "timerColor";
const int DEFAULT_TIMER_COLOR = 0xFF2196F3; // Blue
const String CURRENT_SCHEDULE_ID = 'currentScheduleId';
const String DEFAULT_SCHEDULE_ID = 'default';
const String BACKGROUND_ENABLED = 'backgroundEnabled';

class Prefs {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  // Existing... then add:
  static int get timerColor =>
      instance.getInt(TIMER_COLOR) ?? DEFAULT_TIMER_COLOR;
  static set timerColor(int value) => instance.setInt(TIMER_COLOR, value);

  static String get currentScheduleId =>
      instance.getString(CURRENT_SCHEDULE_ID) ?? DEFAULT_SCHEDULE_ID;
  static set currentScheduleId(String value) =>
      instance.setString(CURRENT_SCHEDULE_ID, value);

  static bool get backgroundEnabled =>
      instance.getBool(BACKGROUND_ENABLED) ?? false;
  static set backgroundEnabled(bool value) =>
      instance.setBool(BACKGROUND_ENABLED, value);
}
