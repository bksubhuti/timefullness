import 'package:flutter/material.dart';
import 'package:timefulness/models/prefs.dart';
import 'package:timefulness/services/background_service.dart';
import 'screens/schedule_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);
  debugPrint("Hive initialized at ${dir.path}");
  await Hive.openBox('schedules');
  await Prefs.init();
  await initializeService();
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
