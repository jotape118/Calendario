import '../entities/calendar_event.dart';

abstract class EventsRepository {
  Future<List<CalendarEvent>> listByDayKey(String dayKey);
  Future<CalendarEvent?> getById(String id);
  Future<void> upsert(CalendarEvent event);
  Future<void> delete(String id);
}
