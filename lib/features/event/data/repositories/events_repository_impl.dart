import 'package:drift/drift.dart' show Value;

import '../../../../core/db/app_database.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  final EventsDao dao;
  EventsRepositoryImpl({required this.dao});

  @override
  Future<List<CalendarEvent>> listByDayKey(String dayKey) async {
    final rows = await dao.listByDayKey(dayKey);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<CalendarEvent?> getById(String id) async {
    final row = await dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> upsert(CalendarEvent e) async {
    await dao.upsert(EventsCompanion(
      id: Value(e.id),
      dayKey: Value(e.dayKey),
      title: Value(e.title),
      notes: Value(e.notes),
      startMin: Value(e.startMin),
      endMin: Value(e.endMin),
      color: Value(e.color),
      createdAt: Value(e.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(e.updatedAt.millisecondsSinceEpoch),
      deletedAt: const Value(null),
    ));
  }

  @override
  Future<void> delete(String id) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await dao.softDelete(id, nowMs);
  }

  CalendarEvent _toEntity(Event r) {
    return CalendarEvent(
      id: r.id,
      dayKey: r.dayKey,
      title: r.title,
      notes: r.notes,
      startMin: r.startMin,
      endMin: r.endMin,
      color: r.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );
  }
}
