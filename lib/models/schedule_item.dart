import 'package:flutter/material.dart';

class ScheduleItem {
  String startTime;
  String endTime;
  String activity;
  bool done;

  ScheduleItem({
    required this.startTime,
    required this.endTime,
    required this.activity,
    this.done = false,
  });

  factory ScheduleItem.fromCsv(Map<String, dynamic> row) {
    final time = row['Time'] ?? '';
    debugPrint("⏱ Parsing time: '$time'");

    final timeParts = time.split('–');
    final start = timeParts.length > 0 ? timeParts[0].trim() : '';
    final end = timeParts.length > 1 ? timeParts[1].trim() : '';

    return ScheduleItem(
      startTime: start,
      endTime: end,
      activity: row['Activity'] ?? '',
      done: (row['Done']?.toString().toLowerCase() == 'true'),
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility with old format
    if (json.containsKey('time') && !json.containsKey('startTime')) {
      return ScheduleItem(
        startTime: json['time'],
        endTime:
            json['time'], // Default to same time for backward compatibility
        activity: json['activity'],
        done: json['done'] ?? false,
      );
    }

    return ScheduleItem(
      startTime: json['startTime'],
      endTime: json['endTime'],
      activity: json['activity'],
      done: json['done'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'activity': activity,
      'done': done,
    };
  }
}
