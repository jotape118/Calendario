class CalendarEvent {
  final String id;
  final String dayKey; // YYYY-MM-DD
  final String title;
  final String? notes;
  final int? startMin;
  final int? endMin;
  final int color; // ARGB int
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.dayKey,
    required this.title,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.startMin,
    this.endMin,
  });
}
