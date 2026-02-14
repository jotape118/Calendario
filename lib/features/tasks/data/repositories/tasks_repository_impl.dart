import 'package:drift/drift.dart' show Value;

import '../../../../core/db/app_database.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TasksDao dao;
  TasksRepositoryImpl({required this.dao});

  @override
  Future<TaskItem?> getById(String id) async {
    final row = await dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<TaskItem>> listAll() async {
    final rows = await dao.listAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<TaskItem>> listFree() async {
    final rows = await dao.listFree();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<TaskItem>> listByDayKey(String dayKey) async {
    final rows = await dao.listByDayKey(dayKey);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<TaskItem>> listByEventId(String eventId) async {
    final rows = await dao.listByEventId(eventId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> upsert(TaskItem t) async {
    await dao.upsert(TasksCompanion(
      id: Value(t.id),
      title: Value(t.title),
      notes: Value(t.notes),
      targetType: Value(t.targetType.index),
      dayKey: Value(t.dayKey),
      eventId: Value(t.eventId),
      isDone: Value(t.isDone),
      createdAt: Value(t.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(t.updatedAt.millisecondsSinceEpoch),
      deletedAt: const Value(null),
    ));
  }

  @override
  Future<void> toggleDone(String id, bool done) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await dao.toggleDone(id, done, now);
  }

  @override
  Future<void> delete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await dao.softDelete(id, now);
  }

  TaskItem _toEntity(TaskRow r) {
    return TaskItem(
      id: r.id,
      title: r.title,
      notes: r.notes,
      targetType: TaskTargetType.values[r.targetType],
      dayKey: r.dayKey,
      eventId: r.eventId,
      isDone: r.isDone,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );
  }
}
