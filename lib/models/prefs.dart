import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String TIMER_COLOR = "timerColor";
const String CURRENT_SCHEDULE_ID = 'currentScheduleId';
const String DEFAULT_SCHEDULE_ID = 'default';
const String BACKGROUND_ENABLED = 'backgroundEnabled';
const String DESTINATION_TIME = 'destinationTime';
const String ACTIVE_TIMER_DURATION = 'activeTimerDuration';

const int DEFAULT_TIMER_COLOR = 0xFF2196F3; // Blue

class Prefs {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async {
    instance = await SharedPreferences.getInstance();
    debugPrint(
      'Loaded Prefs: currentScheduleId=$currentScheduleId, '
      'timerColor=$timerColor',
    );
    return instance;
  }

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

  static DateTime? get destinationTime {
    final iso = instance.getString(DESTINATION_TIME);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  static set destinationTime(DateTime? value) {
    if (value == null) {
      instance.remove(DESTINATION_TIME);
    } else {
      instance.setString(DESTINATION_TIME, value.toIso8601String());
    }
  }

  static int get activeTimerDuration =>
      instance.getInt(ACTIVE_TIMER_DURATION) ?? 0;

  static set activeTimerDuration(int value) =>
      instance.setInt(ACTIVE_TIMER_DURATION, value);
}
