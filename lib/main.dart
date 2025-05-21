import 'package:flutter/material.dart';
import 'package:timefulness/models/prefs.dart';
import 'screens/schedule_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
