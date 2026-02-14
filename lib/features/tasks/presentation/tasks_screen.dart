import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../event/domain/entities/calendar_event.dart';
import '../domain/entities/task_item.dart';

enum _TasksFilter { all, pending, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _loading = true;

  _TasksFilter _filter = _TasksFilter.all;

  List<TaskItem> free = [];
  List<TaskItem> today = [];

  // cache simple para badges de eventos (id -> title)
  final Map<String, String> _eventTitleCache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = AppServices.I.tasksRepo;

    final todayKey = _toDayKey(DateTime.now());

    final r1 = await repo.listFree();
    final r2 = await repo.listByDayKey(todayKey);

    // precarga títulos de eventos para las tareas que lo necesiten (si aparecen en HOY o SIN FECHA)
    final eventIds = <String>{
      ...r1.map((t) => t.eventId).whereType<String>(),
      ...r2.map((t) => t.eventId).whereType<String>(),
    };

    for (final id in eventIds) {
      if (_eventTitleCache.containsKey(id)) continue;
      final ev = await AppServices.I.eventsRepo.getById(id);
      if (ev != null) _eventTitleCache[id] = ev.title;
    }

    if (!mounted) return;
    setState(() {
      free = r1;
      today = r2;
      _loading = false;
    });
  }

  List<TaskItem> _applyFilter(List<TaskItem> items) {
    switch (_filter) {
      case _TasksFilter.all:
        return items;
      case _TasksFilter.pending:
        return items.where((t) => !t.isDone).toList();
      case _TasksFilter.done:
        return items.where((t) => t.isDone).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFiltered = _applyFilter(today);
    final freeFiltered = _applyFilter(free);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.background, Color(0xFF07070A), AppColors.background],
            ),
          ),
        ),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Lista de Tareas',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.95),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Pills
                _FilterPills(
                  value: _filter,
                  onChange: (v) => setState(() => _filter = v),
                ),

                const SizedBox(height: 16),

                if (_loading) ...[
                  const SizedBox(height: 40),
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  if (todayFiltered.isNotEmpty) ...[
                    _SectionTitleRow(
                      left: 'HOY',
                      right: '${todayFiltered.where((t) => !t.isDone).length} activas',
                    ),
                    const SizedBox(height: 10),
                    ...todayFiltered.map(
                      (t) => _TaskCard(
                        t: t,
                        badgeLabel: _badgeForTask(t),
                        badgeIcon: _badgeIconForTask(t),
                        onToggle: (v) async {
                          await AppServices.I.tasksRepo.toggleDone(t.id, v);
                          await _load();
                        },
                        onEdit: () => context.push(AppRoutes.taskEdit.replaceAll(':id', t.id)).then((_) => _load()),
                        onDelete: () async {
                          final ok = await _confirmDelete(context);
                          if (!ok) return;
                          await AppServices.I.tasksRepo.delete(t.id);
                          await _load();
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // En tu data actual: "PENDIENTES" es básicamente sin fecha (free)
                  _SectionTitleRow(left: 'PENDIENTES', right: ''),
                  const SizedBox(height: 10),

                  if (freeFiltered.isEmpty)
                    _EmptyHint(text: 'No hay tareas sin fecha.')
                  else
                    ...freeFiltered.map(
                      (t) => _TaskCard(
                        t: t,
                        badgeLabel: _badgeForTask(t),
                        badgeIcon: _badgeIconForTask(t),
                        onToggle: (v) async {
                          await AppServices.I.tasksRepo.toggleDone(t.id, v);
                          await _load();
                        },
                        onEdit: () => context.push(AppRoutes.taskEdit.replaceAll(':id', t.id)).then((_) => _load()),
                        onDelete: () async {
                          final ok = await _confirmDelete(context);
                          if (!ok) return;
                          await AppServices.I.tasksRepo.delete(t.id);
                          await _load();
                        },
                      ),
                    ),

                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => context.push(AppRoutes.taskNew).then((_) => _load()),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.textPrimary,
                    tooltip: 'Nueva tarea',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _badgeIconForTask(TaskItem t) {
    if (t.eventId != null) return Icons.event;
    if (t.dayKey != null) return Icons.calendar_month;
    return Icons.circle_outlined;
  }

  String? _badgeForTask(TaskItem t) {
    if (t.eventId != null) {
      final title = _eventTitleCache[t.eventId!];
      return title == null ? 'Evento' : title;
    }
    if (t.dayKey != null) {
      // formato tipo mock "15 Mar"
      final d = _fromDayKey(t.dayKey!);
      return '${d.day} ${_mon3(d.month)}';
    }
    return null;
  }

  static String _mon3(int m) => ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][m - 1];

  static DateTime _fromDayKey(String dayKey) {
    final p = dayKey.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static String _toDayKey(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$mm-$dd';
  }
}

class _FilterPills extends StatelessWidget {
  final _TasksFilter value;
  final ValueChanged<_TasksFilter> onChange;

  const _FilterPills({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Pill(
            text: 'Todas',
            selected: value == _TasksFilter.all,
            onTap: () => onChange(_TasksFilter.all),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            text: 'Pendientes',
            selected: value == _TasksFilter.pending,
            onTap: () => onChange(_TasksFilter.pending),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            text: 'Completadas',
            selected: value == _TasksFilter.done,
            onTap: () => onChange(_TasksFilter.done),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accentViolet.withOpacity(0.25) : AppColors.surface.withOpacity(0.22);
    final border = selected ? AppColors.accentViolet.withOpacity(0.60) : AppColors.borderTop;
    final color = selected ? AppColors.accentViolet : AppColors.textMuted2.withOpacity(0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final String left;
  final String right;

  const _SectionTitleRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          left,
          style: TextStyle(
            color: AppColors.textMuted2.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: AppColors.borderTop)),
        if (right.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            right,
            style: TextStyle(
              color: AppColors.accentViolet.withOpacity(0.95),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem t;
  final String? badgeLabel;
  final IconData badgeIcon;

  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _TaskCard({
    required this.t,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderTop),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: t.isDone,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: AppColors.accentViolet,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        decoration: t.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white24,
                      ),
                    ),
                    if (badgeLabel != null) ...[
                      const SizedBox(height: 8),
                      _Badge(
                        text: badgeLabel!,
                        icon: badgeIcon,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                _MiniIconButton(icon: Icons.edit_outlined, onTap: onEdit),
                const SizedBox(height: 8),
                _MiniIconButton(icon: Icons.delete_outline, onTap: () async => await onDelete()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentViolet.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentViolet.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentViolet.withOpacity(0.95)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppColors.accentViolet.withOpacity(0.95),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: AppColors.textMuted2.withOpacity(0.9), size: 18),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderTop),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted2.withOpacity(0.75),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar tarea'),
      content: const Text('¿Seguro que quieres eliminar esta tarea?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return ok == true;
}
