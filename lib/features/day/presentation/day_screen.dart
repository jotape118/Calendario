import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../event/domain/entities/calendar_event.dart';
import '../../tasks/domain/entities/task_item.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  final c = AppServices.I.dayController;

  // ✅ Forzar refresh de FutureBuilder de tareas dentro de tarjetas
  int _tasksReloadTick = 0;
  void _bumpTasksReload() => setState(() => _tasksReloadTick++);

  @override
  void initState() {
    super.initState();
    c.init();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        const _DayBackground(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset + 120),
            child: AnimatedBuilder(
              animation: c,
              builder: (_, __) {
                final days = _buildDayChips(c.selectedDay);

                final allDay = c.events.where((e) => e.startMin == null).toList();
                final timed = c.events.where((e) => e.startMin != null).toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        child: _Header(
                          title: 'CALENDARIO',
                          onSettings: () => context.push(AppRoutes.settings),
                          onNewEvent: () => context.push(AppRoutes.eventNew),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: _DayStrip(
                          days: days,
                          selectedIndex: 2,
                          onSelect: (i) => c.setDay(days[i].date),
                          onPrev: c.prevDay,
                          onNext: c.nextDay,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: c.loading
                            ? const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : Column(
                                children: [
                                  if (allDay.isNotEmpty) ...[
                                    _AllDaySection(
                                      events: allDay,
                                      onEdit: (e) => context.push('/event/edit/${e.id}'),
                                      onDelete: (e) async {
                                        await AppServices.I.eventsRepo.delete(e.id);
                                        await c.load();
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _Timeline(
                                    events: timed,
                                    tasksReloadTick: _tasksReloadTick,
                                    onTasksChanged: () async {
                                      _bumpTasksReload();
                                    },
                                    onEdit: (e) => context.push('/event/edit/${e.id}'),
                                    onDelete: (e) async {
                                      await AppServices.I.eventsRepo.delete(e.id);
                                      await c.load();
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_DayChip> _buildDayChips(DateTime center) {
    final base = DateTime(center.year, center.month, center.day);
    return List.generate(5, (i) {
      final d = base.add(Duration(days: i - 2));
      return _DayChip(
        date: d,
        label: i == 2 ? '${d.day}' : '${d.day.toString().padLeft(2, '0')} ${_mon3(d.month)}',
        month: i == 2 ? _monthName(d.month) : null,
        isCenter: i == 2,
      );
    });
  }

  String _mon3(int m) => ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'][m - 1];
  String _monthName(int m) =>
      ['ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'][m - 1];
}

class _DayBackground extends StatelessWidget {
  const _DayBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF07070A), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.w(0.0), AppColors.w(0.10), AppColors.w(0.0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accentViolet.withOpacity(0.22), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onSettings;
  final VoidCallback onNewEvent;

  const _Header({required this.title, required this.onSettings, required this.onNewEvent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textMuted2.withOpacity(0.85),
            fontSize: 14,
            letterSpacing: 2.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onNewEvent,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.textPrimary,
          tooltip: 'Nuevo evento',
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
          color: AppColors.textPrimary,
          tooltip: 'Ajustes',
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  final List<_DayChip> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DayStrip({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: List.generate(days.length, (i) {
              final d = days[i];
              if (d.isCenter) {
                return _CenterDatePill(
                  month: d.month ?? '',
                  day: d.label,
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                );
              }
              return Expanded(
                child: Center(
                  child: _SmallDateText(
                    label: d.label,
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        _ArrowButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderTop),
        ),
        child: Icon(icon, color: AppColors.textMuted.withOpacity(0.85), size: 22),
      ),
    );
  }
}

class _SmallDateText extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SmallDateText({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted2.withOpacity(0.8);
    final weight = selected ? FontWeight.w700 : FontWeight.w600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: weight,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _CenterDatePill extends StatelessWidget {
  final String month;
  final String day;
  final bool selected;
  final VoidCallback onTap;

  const _CenterDatePill({required this.month, required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.deepViolet.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentViolet.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              month.toUpperCase(),
              style: TextStyle(
                color: AppColors.accentViolet.withOpacity(0.95),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDaySection extends StatelessWidget {
  final List<CalendarEvent> events;
  final void Function(CalendarEvent e) onEdit;
  final Future<void> Function(CalendarEvent e) onDelete;

  const _AllDaySection({
    required this.events,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const timeCol = 62.0;
    const gap = 14.0;
    final left = timeCol + gap;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: left),
            child: Row(
              children: [
                Text(
                  'TODO EL DÍA',
                  style: TextStyle(
                    color: AppColors.textMuted2.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: AppColors.borderTop)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...events.map((e) {
            return Padding(
              padding: EdgeInsets.only(left: left, bottom: 10),
              child: _AllDayCard(
                e: e,
                onTap: () => onEdit(e),
                onEdit: () => onEdit(e),
                onDelete: () => onDelete(e),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _AllDayCard extends StatelessWidget {
  final CalendarEvent e;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _AllDayCard({
    required this.e,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = Color(e.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.40),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderTop),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [barColor.withOpacity(0.95), barColor.withOpacity(0.55)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.event, color: barColor.withOpacity(0.95), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: AppColors.textMuted2.withOpacity(0.8)),
                    color: AppColors.surface,
                    onSelected: (v) async {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') {
                        final ok = await _confirmDeleteDialog(context, title: 'Eliminar evento', text: '¿Seguro que quieres eliminar este evento?');
                        if (ok) await onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<CalendarEvent> events;
  final int tasksReloadTick;
  final Future<void> Function() onTasksChanged;
  final void Function(CalendarEvent e) onEdit;
  final Future<void> Function(CalendarEvent e) onDelete;

  const _Timeline({
    required this.events,
    required this.tasksReloadTick,
    required this.onTasksChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const baseStartHour = 8;
    const baseEndHour = 14;

    int startHour = baseStartHour;
    int endHour = baseEndHour;

    if (events.isNotEmpty) {
      final minMin = events.map((e) => e.startMin!).reduce(math.min);
      final maxMin = events.map((e) => (e.endMin ?? e.startMin! + 60)).reduce(math.max);
      startHour = math.min(baseStartHour, (minMin ~/ 60).clamp(0, 23));
      endHour = math.max(baseEndHour, ((maxMin + 59) ~/ 60).clamp(0, 23));
    }

    const slotHeight = 84.0;
    final totalHeight = (endHour - startHour + 1) * slotHeight;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, c) {
          const timeCol = 62.0;
          const gap = 14.0;
          final gridWidth = c.maxWidth - timeCol - gap;

          return Stack(
            children: [
              Positioned.fill(
                child: _TimelineGrid(
                  startHour: startHour,
                  endHour: endHour,
                  slotHeight: slotHeight,
                  timeColumnWidth: timeCol,
                  gap: gap,
                ),
              ),
              ...events.map((e) {
                final top = ((e.startMin! - startHour * 60) / 60.0) * slotHeight;
                final end = e.endMin ?? (e.startMin! + 60);
                final height = math.max(1.0, ((end - e.startMin!) / 60.0) * slotHeight);

                return Positioned(
                  left: timeCol + gap,
                  right: 0,
                  top: top + 6,
                  height: height - 6,
                  child: _EventCard(
                    key: ValueKey('event-${e.id}-$tasksReloadTick'),
                    e: e,
                    width: gridWidth,
                    onEdit: () => onEdit(e),
                    onDelete: () => onDelete(e),
                    onTasksChanged: onTasksChanged,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineGrid extends StatelessWidget {
  final int startHour;
  final int endHour;
  final double slotHeight;
  final double timeColumnWidth;
  final double gap;

  const _TimelineGrid({
    required this.startHour,
    required this.endHour,
    required this.slotHeight,
    required this.timeColumnWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(endHour - startHour + 1, (i) {
        final hour = startHour + i;
        final label = '${hour.toString().padLeft(2, '0')}:00';

        return SizedBox(
          height: slotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textMuted2.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(top: 14, left: 0, right: 0, child: Container(height: 1, color: AppColors.borderTop)),
                    Positioned(top: 0, bottom: 0, left: 0, child: Container(width: 1, color: AppColors.borderTop)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent e;
  final double width;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function() onTasksChanged;

  const _EventCard({
    super.key,
    required this.e,
    required this.width,
    required this.onEdit,
    required this.onDelete,
    required this.onTasksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = Color(e.color);
    final timeText = '${_fmtMin(e.startMin!)} — ${_fmtMin(e.endMin ?? (e.startMin! + 60))}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [barColor.withOpacity(0.95), barColor.withOpacity(0.55)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconAction(icon: Icons.edit_outlined, onTap: onEdit),
                      const SizedBox(width: 10),
                      _IconAction(
                        icon: Icons.delete_outline,
                        onTap: () async {
                          final ok = await _confirmDeleteDialog(context, title: 'Eliminar evento', text: '¿Seguro que quieres eliminar este evento?');
                          if (ok) await onDelete();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _EventTasksPanel(
                      eventId: e.id,
                      onChanged: onTasksChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtMin(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EventTasksPanel extends StatelessWidget {
  final String eventId;
  final Future<void> Function() onChanged;

  const _EventTasksPanel({
    required this.eventId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskItem>>(
      future: AppServices.I.tasksRepo.listByEventId(eventId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderTop),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snap.data ?? const [];

        if (tasks.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderTop),
            ),
            padding: const EdgeInsets.all(14),
            child: Text(
              'Sin tareas asociadas.',
              style: TextStyle(
                color: AppColors.textMuted2.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderTop),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = tasks[i];

              return InkWell(
                onTap: () async {
                  await AppServices.I.tasksRepo.toggleDone(t.id, !t.isDone);
                  await onChanged();
                },
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    _CircleCheck(done: t.isDone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.isDone ? AppColors.textMuted2.withOpacity(0.65) : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          decoration: t.isDone ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CircleCheck extends StatelessWidget {
  final bool done;
  const _CircleCheck({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.accentViolet : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.accentViolet.withOpacity(0.9) : AppColors.textMuted2.withOpacity(0.35),
          width: 1.4,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: AppColors.textMuted2.withOpacity(0.9), size: 22),
      ),
    );
  }
}

Future<bool> _confirmDeleteDialog(BuildContext context, {required String title, required String text}) async {
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
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
      );
    },
  );
  return ok == true;
}

class _DayChip {
  final DateTime date;
  final String label;
  final String? month;
  final bool isCenter;
  const _DayChip({required this.date, required this.label, this.month, this.isCenter = false});
}
