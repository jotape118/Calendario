import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell/shell_scaffold.dart';

import 'package:calendario_voz/features/day/presentation/day_screen.dart';
import 'package:calendario_voz/features/tasks/presentation/tasks_screen.dart';
import 'package:calendario_voz/features/settings/presentation/settings_screen.dart';

import 'package:calendario_voz/features/event/presentation/event_edit_screen.dart';
import 'package:calendario_voz/features/tasks/presentation/task_edit_screen.dart';
import 'package:calendario_voz/features/tasks/presentation/pick_day_screen.dart';
import 'package:calendario_voz/features/tasks/presentation/pick_event_sheet.dart';

import 'package:calendario_voz/features/capture/presentation/capture_sheet.dart';

class AppRoutes {
  static const day = '/day';
  static const tasks = '/tasks';
  static const settings = '/settings';

  // Tabs (navbar)
  static const newEntry = '/new';
  static const micro = '/micro';

  // Manual (sub-flujos)
  static const eventNew = '/event/new';
  static const eventEdit = '/event/edit/:id';
  static const taskNew = '/task/new';
  static const taskEdit = '/task/edit/:id';
  static const pickDay = '/task/pick-day';
  static const pickEvent = '/task/pick-event';

  // Legacy alias
  static const capture = '/capture';
}

String _todayKey() {
  final d = DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.day,
    routes: [
      ShellRoute(
        builder: (_, __, child) => ShellScaffold(child: child),
        routes: [
          // Tabs principales
          GoRoute(
            path: AppRoutes.day,
            pageBuilder: (_, __) => const NoTransitionPage(child: DayScreen()),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, __) => const NoTransitionPage(child: TasksScreen()),
          ),

          // ✅ Tab Nuevo (selector)
          GoRoute(
            path: AppRoutes.newEntry,
            redirect: (_, __) => AppRoutes.taskNew,
          ),

          // ✅ Tab Micro (captura)
          GoRoute(
            path: AppRoutes.micro,
            pageBuilder: (_, __) => const NoTransitionPage(child: CaptureSheet()),
          ),

          // Sub-rutas bajo el shell (para mantener navbar)
          GoRoute(
            path: AppRoutes.eventNew,
            builder: (_, __) => const EventEditScreen.newEvent(),
          ),
          GoRoute(
            path: AppRoutes.eventEdit,
            builder: (_, state) => EventEditScreen.edit(
              eventId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.taskNew,
            builder: (_, __) => const TaskEditScreen.newTask(),
          ),
          GoRoute(
            path: AppRoutes.taskEdit,
            builder: (_, state) => TaskEditScreen.edit(
              taskId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.pickDay,
            pageBuilder: (_, __) => const MaterialPage(
              fullscreenDialog: true,
              child: PickDayScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.pickEvent,
            pageBuilder: (_, state) {
              final dayKey = (state.extra as String?) ?? _todayKey();
              return MaterialPage(
                fullscreenDialog: true,
                child: PickEventSheet(dayKey: dayKey),
              );
            },
          ),
        ],
      ),

      // Ajustes (fuera del shell por ahora)
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      // Alias legacy: si alguien usa /capture lo mandamos a /micro
      GoRoute(
        path: AppRoutes.capture,
        redirect: (_, __) => AppRoutes.micro,
      ),
    ],
  );
}
