// ===== lib/services/hive_schedule_repository.dart =====

import '../models/schedule_item.dart';
import 'schedule_repository.dart';
import 'package:hive/hive.dart';

class HiveScheduleRepository implements ScheduleRepository {
  final Box _box;

  HiveScheduleRepository(this._box);

  static const _activeKey = 'activeSchedule';

  @override
  Future<List<String>> listScheduleIds() async {
    return _box.keys
        .whereType<String>()
        .where((key) => key != _activeKey)
        .toList();
  }

  @override
  Future<List<ScheduleItem>> loadSchedule(String scheduleId) async {
    final raw = _box.get(scheduleId);
    if (raw is List) {
      return (raw)
          .map((e) => Map<String, dynamic>.from(e))
          .map((e) => ScheduleItem.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveSchedule(String scheduleId, List<ScheduleItem> items) async {
    await _box.put(scheduleId, items.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _box.delete(scheduleId);
  }

  @override
  Future<String?> getActiveScheduleId() async {
    return _box.get(_activeKey);
  }

  @override
  Future<void> setActiveScheduleId(String scheduleId) async {
    await _box.put(_activeKey, scheduleId);
  }
}
