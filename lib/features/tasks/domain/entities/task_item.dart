enum TaskTargetType { free, day, event }

class TaskItem {
  final String id;
  final String title;
  final String? notes;

  final TaskTargetType targetType;
  final String? dayKey;   // YYYY-MM-DD (si day)
  final String? eventId;  // (si event)

  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.title,
    required this.targetType,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.dayKey,
    this.eventId,
  });
}
