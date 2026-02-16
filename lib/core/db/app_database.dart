import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Events extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get dayKey => text()(); // YYYY-MM-DD
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();

  IntColumn get startMin => integer().nullable()(); // 0..1439
  IntColumn get endMin => integer().nullable()(); // 0..1439

  IntColumn get color => integer()(); // ARGB int

  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get updatedAt => integer()(); // epoch ms
  IntColumn get deletedAt => integer().nullable()(); // soft delete

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();

  // 0=free, 1=day, 2=event
  IntColumn get targetType => integer()();

  // Solo si targetType == 1
  TextColumn get dayKey => text().nullable()(); // YYYY-MM-DD

  // Solo si targetType == 2
  TextColumn get eventId => text().nullable()(); // events.id

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get updatedAt => integer()(); // epoch ms
  IntColumn get deletedAt => integer().nullable()(); // soft delete

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<List<Event>> listByDayKey(String dayKey) {
    final q = select(events)
      ..where((t) => t.dayKey.equals(dayKey) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.startMin.isNull()),
        (t) => OrderingTerm(expression: t.startMin),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return q.get();
  }

  Future<Event?> getById(String id) {
    return (select(events)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> upsert(EventsCompanion data) async {
    await into(events).insertOnConflictUpdate(data);
  }

  Future<void> softDelete(String id, int nowMs) async {
    await (update(events)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(EventsCompanion(
      deletedAt: Value(nowMs),
      updatedAt: Value(nowMs),
    ));
  }
}

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Future<TaskRow?> getById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<TaskRow>> listAll() {
    final q = select(tasks)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isDone),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.get();
  }

  Future<List<TaskRow>> listFree() {
    final q = select(tasks)
      ..where((t) => t.targetType.equals(0) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isDone),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.get();
  }

  Future<List<TaskRow>> listByDayKey(String dayKey) {
    final q = select(tasks)
      ..where((t) =>
          t.targetType.equals(1) & t.dayKey.equals(dayKey) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isDone),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.get();
  }

  Future<List<TaskRow>> listByEventId(String eventId) {
    final q = select(tasks)
      ..where((t) =>
          t.targetType.equals(2) &
          t.eventId.equals(eventId) &
          t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isDone),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return q.get();
  }

  Future<void> upsert(TasksCompanion data) async {
    await into(tasks).insertOnConflictUpdate(data);
  }

  Future<void> toggleDone(String id, bool done, int nowMs) async {
    await (update(tasks)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(TasksCompanion(
      isDone: Value(done),
      updatedAt: Value(nowMs),
    ));
  }

  Future<void> softDelete(String id, int nowMs) async {
    await (update(tasks)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(TasksCompanion(
      deletedAt: Value(nowMs),
      updatedAt: Value(nowMs),
    ));
  }
}

@DriftDatabase(tables: [Events, Tasks], daos: [EventsDao, TasksDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2: se agrega tasks
          if (from < 2) {
            await m.createTable(tasks);
          }
        },
        beforeOpen: (details) async {
          // Por si luego quieres FKs
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/calendar_voice.sqlite');
      return NativeDatabase(file);
    });
  }
}
