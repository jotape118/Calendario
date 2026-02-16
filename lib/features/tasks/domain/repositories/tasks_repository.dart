import '../entities/task_item.dart';

abstract class TasksRepository {
  Future<TaskItem?> getById(String id);

  Future<List<TaskItem>> listAll();
  Future<List<TaskItem>> listFree();
  Future<List<TaskItem>> listByDayKey(String dayKey);
  Future<List<TaskItem>> listByEventId(String eventId);

  Future<void> upsert(TaskItem task);
  Future<void> toggleDone(String id, bool done);
  Future<void> delete(String id);
}
