import 'package:flutter/material.dart';
import 'screens/schedule_screen.dart';

void main() {
  runApp(const TimefullnessApp());
}

class TimefullnessApp extends StatelessWidget {
  const TimefullnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timefullness',
      home: const ScheduleScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
