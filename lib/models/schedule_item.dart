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
    try {
      return ScheduleItem(
        id: json['id'] ?? UniqueKey().toString(),
        startTime: (json['startTime'] ?? '').toString(),
        endTime: (json['endTime'] ?? '').toString(),
        activity: (json['activity'] ?? '').toString(),
        done: json['done'] ?? false,
        checkedAt:
            DateTime.tryParse(json['checkedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('❌ Error parsing ScheduleItem: $e');
      rethrow;
    }
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
