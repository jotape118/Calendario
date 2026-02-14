import '../../domain/entities/calendar_event.dart';

class EventMapper {
  static CalendarEvent fromRow(Map<String, Object?> r) {
    return CalendarEvent(
      id: r['id'] as String,
      dayKey: r['day_key'] as String,
      title: r['title'] as String,
      notes: r['notes'] as String?,
      startMin: r['start_min'] as int?,
      endMin: r['end_min'] as int?,
      color: r['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    );
  }

  static Map<String, Object?> toRow(CalendarEvent e) {
    return {
      'id': e.id,
      'day_key': e.dayKey,
      'title': e.title,
      'notes': e.notes,
      'start_min': e.startMin,
      'end_min': e.endMin,
      'color': e.color,
      'created_at': e.createdAt.millisecondsSinceEpoch,
      'updated_at': e.updatedAt.millisecondsSinceEpoch,
      'deleted_at': null,
    };
  }
}
