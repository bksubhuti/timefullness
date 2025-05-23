import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationService = NotificationService();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  // Singleton pattern to ensure a single instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Instance of FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo')); // or your desired zone

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    bool isRecurring = false,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Alerts',
      channelDescription: 'Channel for timer notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('bell'),
    );

    const iosDetails = DarwinNotificationDetails(sound: 'bell.aiff');

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Try exact alarm, fallback to inexact if not allowed
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final exactPermitted =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint(
      "🔔 Scheduling notification at: $tzTime (local) "
      "with ${exactPermitted ? 'EXACT' : 'INEXACT'} mode",
    );

    final pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (var item in pending) {
      debugPrint(
        "⏰ Pending: id=${item.id}, title=${item.title}, body=${item.body}",
      );
    }
  }

  /// Cancels a notification by its ID.
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
