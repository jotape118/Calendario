import '../core/db/app_database.dart';

import '../features/event/data/repositories/events_repository_impl.dart';
import '../features/event/domain/repositories/events_repository.dart';

import '../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../features/tasks/domain/repositories/tasks_repository.dart';

import '../features/day/presentation/day_controller.dart';

class AppServices {
  AppServices._();
  static final AppServices I = AppServices._();

  // Drift DB
  final AppDatabase db = AppDatabase();

  // Repos
  late final EventsRepository eventsRepo = EventsRepositoryImpl(dao: db.eventsDao);
  late final TasksRepository tasksRepo = TasksRepositoryImpl(dao: db.tasksDao);

  // Controllers
  late final DayController dayController = DayController(eventsRepo);
}
