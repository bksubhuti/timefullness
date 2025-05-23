import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Global singleton instance
final notificationService = NotificationService();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _selectNotificationStream =
      StreamController<NotificationResponse>.broadcast();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      final bool? initialized = await _flutterLocalNotificationsPlugin
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (NotificationResponse response) {
              _selectNotificationStream.add(response);
            },
            onDidReceiveBackgroundNotificationResponse:
                _notificationTapBackground,
          );
      debugPrint('🔔 NotificationService initialized: $initialized');

      await _requestPermissions();
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        final bool? notificationsEnabled =
            await androidPlugin?.areNotificationsEnabled() ?? false;
        if (!notificationsEnabled!) {
          final bool? granted =
              await androidPlugin?.requestNotificationsPermission();
          debugPrint('🔔 Notification permission granted: $granted');
        }
        final bool? exactAlarmPermitted =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (!exactAlarmPermitted!) {
          const AndroidIntent intent = AndroidIntent(
            action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
          debugPrint('🔔 Requested exact alarm permission');
        }
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();
        final bool? granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('🔔 iOS notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    bool isRecurring = false,
  }) async {
    try {
      final tzTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'timer_channel',
            'Timer Alerts',
            channelDescription: 'Channel for timer notifications',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('bell'),
          );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'bell.aiff',
      );
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool exactPermitted =
          await androidPlugin?.canScheduleExactNotifications() ?? false;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        platformDetails,
        androidScheduleMode:
            exactPermitted
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexact,
        payload: 'notification_$id',
      );

      debugPrint(
        "🔔 Notification scheduled: id=$id, title=$title, time=$tzTime, "
        "mode=${exactPermitted ? 'EXACT' : 'INEXACT'}",
      );
    } catch (e) {
      debugPrint("❌ Error scheduling notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint("🔔 Notification cancelled: id=$id");
    } catch (e) {
      debugPrint("❌ Error cancelling notification: $e");
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint("🔔 All notifications cancelled");
    } catch (e) {
      debugPrint("❌ Error cancelling all notifications: $e");
    }
  }

  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint(
      "🔔 Background notification tapped: id=${response.id}, payload=${response.payload}",
    );
  }

  Stream<NotificationResponse> get notificationStream =>
      _selectNotificationStream.stream;
}
