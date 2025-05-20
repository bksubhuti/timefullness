import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String startTime;
  final String endTime;
  final String activity;
  bool done;
  DateTime checkedAt;

  ScheduleItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.activity,
    this.done = false,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory ScheduleItem.fromCsv(Map<String, dynamic> row) {
    final time = row['Time'] ?? '';
    debugPrint("⏱ Parsing time: '$time'");

    final timeParts = time.split('–');
    final start = timeParts.isNotEmpty ? timeParts[0].trim() : '';
    final end = timeParts.length > 1 ? timeParts[1].trim() : '';

    return ScheduleItem(
      id: UniqueKey().toString(),
      startTime: start,
      endTime: end,
      activity: row['Activity'] ?? '',
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final parsedCheckedAt = json['checkedAt'];
    return ScheduleItem(
      id: json['id'] ?? UniqueKey().toString(),
      startTime: json['startTime'],
      endTime: json['endTime'],
      activity: json['activity'],
      done: json['done'] ?? false,
      checkedAt:
          parsedCheckedAt != null
              ? DateTime.tryParse(parsedCheckedAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0)
              : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'activity': activity,
      'done': done,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }
}
