import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String timerColorPref = "timerColor";
const String currentScheduleIdPref = 'currentScheduleId';
const String defaultScheduleId = 'Default';
const String backgroundEnabledPref = 'backgroundEnabled';
const String destinationTimePref = 'destinationTime';
const String activeTimerDurationPref = 'activeTimerDuration';
const String remainingSecondsPref = 'remainingSeconds';
const String timerPausedPref = 'timerPaused';
const String shouldPlaySoundOnCheckPref = 'shouldPlaySoundOnCheck';

const int defaultTimerColor = 0xFF2196F3; // Blue

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
      instance.getInt(timerColorPref) ?? defaultTimerColor;
  static set timerColor(int value) => instance.setInt(timerColorPref, value);

  static String get currentScheduleId =>
      instance.getString(currentScheduleIdPref) ?? defaultScheduleId;
  static set currentScheduleId(String value) =>
      instance.setString(currentScheduleIdPref, value);

  static bool get backgroundEnabled =>
      instance.getBool(backgroundEnabledPref) ?? false;
  static set backgroundEnabled(bool value) =>
      instance.setBool(backgroundEnabledPref, value);

  static DateTime? get destinationTime {
    final iso = instance.getString(destinationTimePref);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  static set destinationTime(DateTime? value) {
    if (value == null) {
      instance.remove(destinationTimePref);
    } else {
      instance.setString(destinationTimePref, value.toIso8601String());
    }
  }

  static int get activeTimerDuration =>
      instance.getInt(activeTimerDurationPref) ?? 0;
  static set activeTimerDuration(int value) =>
      instance.setInt(activeTimerDurationPref, value);

  static int? get remainingSeconds =>
      instance.containsKey(remainingSecondsPref)
          ? instance.getInt(remainingSecondsPref)
          : null;
  static set remainingSeconds(int? value) {
    if (value == null) {
      instance.remove(remainingSecondsPref);
    } else {
      instance.setInt(remainingSecondsPref, value);
    }
  }

  static bool get timerPaused => instance.getBool(timerPausedPref) ?? false;
  static set timerPaused(bool value) =>
      instance.setBool(timerPausedPref, value);

  static bool get shouldPlaySoundOnCheck =>
      instance.getBool(shouldPlaySoundOnCheckPref) ?? true;
  static set shouldPlaySoundOnCheck(bool value) =>
      instance.setBool(shouldPlaySoundOnCheckPref, value);
}
