import 'dart:async';

import 'package:intl/intl.dart';
import 'package:my_time_schedule/constants.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/models/schedule_item.dart';
import 'package:my_time_schedule/plugin.dart';
import 'package:my_time_schedule/services/utilities.dart';

/// from the example file
/// import 'dart:async';
import 'dart:io';
// ignore: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:my_time_schedule/l10n/app_localizations.dart';

Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  if (kIsWeb) {
    return;
  }
  if (Platform.isWindows) {
    return;
  }
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> timerNotification(Duration duration, BuildContext context) async {
  final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);
  final l10n = AppLocalizations.of(context)!;
  Prefs.activeTimerHash = 1;

  //////////////////////////////////////////////////////////
  // create android specific dnd bypass
  const notificationDndBypassDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      kDndBypassTimerChannelId,
      kDndBypassTimerChannelName,
      channelDescription: kDndBypassTimerChannelDescription,
      sound: RawResourceAndroidNotificationSound('bell'),
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.max,
      channelBypassDnd: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'bell.aiff', // Ensure it's included in iOS assets
    ),
    macOS: DarwinNotificationDetails(sound: 'bell.aiff'),
  );
  ///////////////////////////////////////////////////////////////

  const notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      kTimerChannelId,
      kTimerChannelName,
      channelDescription: kTimerChannelDescription,
      sound: RawResourceAndroidNotificationSound('bell'),
      playSound: true,
      importance: Importance.max,
      priority: Priority.max,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'bell.aiff', // Ensure it's included in iOS assets
    ),
    macOS: DarwinNotificationDetails(sound: 'bell.aiff'),
  );

  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      Prefs.activeTimerHash,
      l10n.appName,
      l10n.yourSessionHasEnded,
      scheduledTime,
      (Platform.isAndroid && Prefs.timerBypassDnd)
          ? notificationDndBypassDetails
          : notificationDetails, // bypass if switch
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  } else if (Platform.isLinux || Platform.isWindows) {
    // Fallback: simulate schedule with delayed Timer
    Timer(duration, () async {
      await flutterLocalNotificationsPlugin.show(
        Prefs.activeTimerHash,
        l10n.appName,
        l10n.yourSessionHasEnded,
        notificationDetails,
      );
    });
  }
}

Future<void> scheduleNotification(ScheduleItem item) async {
  try {
    final format = DateFormat('h:mm a', 'en_US');
    final now = DateTime.now();
    final parsed = format.parseStrict(cleanTime(item.startTime));
    final when = DateTime(
      now.year,
      now.month,
      now.day,
      parsed.hour,
      parsed.minute,
    );

    if (when.isBefore(now)) {
      debugPrint('⏩ Skipped scheduling for past time: ${item.startTime}');
      return;
    }

    final tzWhen = tz.TZDateTime.from(when, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      item.id.hashCode,
      'Scheduled: ${item.activity}',
      'Starts at ${item.startTime}',
      tzWhen,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Scheduled Items',
          channelDescription: 'Reminders for scheduled tasks',
          playSound: true, // ✅ use default system sound
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true, // ✅ system sound
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true, // ✅ system sound
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e) {
    debugPrint('❌ Failed to schedule notification for ${item.activity}: $e');
  }
}

Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}
