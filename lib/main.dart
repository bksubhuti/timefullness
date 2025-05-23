import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timefulness/models/prefs.dart';
import 'package:timefulness/services/notification_service.dart';
import 'screens/schedule_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  await requestNotificationPermission();
  await requestExactAlarmIfNeeded();
  await notificationService.init();
  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);
  debugPrint("Hive initialized at ${dir.path}");
  await Hive.openBox('schedules');
  await Prefs.init();
  runApp(const TimefulnessApp());
}

class TimefulnessApp extends StatelessWidget {
  const TimefulnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timefulness',
      home: const ScheduleScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> requestExactAlarmIfNeeded() async {
  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}
