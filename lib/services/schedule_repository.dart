// ===== lib/services/schedule_repository.dart =====

import '../models/schedule_item.dart';

abstract class ScheduleRepository {
  Future<List<String>> listScheduleIds();
  Future<List<ScheduleItem>> loadSchedule(String scheduleId);
  Future<void> saveSchedule(String scheduleId, List<ScheduleItem> items);
  Future<void> deleteSchedule(String scheduleId);
  Future<String?> getActiveScheduleId();
  Future<void> setActiveScheduleId(String scheduleId);
}
