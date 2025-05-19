import 'package:flutter/material.dart';
import 'screens/schedule_screen.dart';

void main() {
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
