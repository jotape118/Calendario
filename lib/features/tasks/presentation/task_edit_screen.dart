import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../event/domain/entities/calendar_event.dart';
import '../domain/entities/task_item.dart';
import '../domain/repositories/tasks_repository.dart';

class TaskEditScreen extends StatefulWidget {
  final String? taskId;
  const TaskEditScreen._({this.taskId});

  const TaskEditScreen.newTask({super.key}) : taskId = null;
  const TaskEditScreen.edit({super.key, required String taskId}) : taskId = taskId;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  TaskTargetType _target = TaskTargetType.free;

  DateTime _pickedDay = DateTime.now();
  String? _pickedEventId;
  CalendarEvent? _pickedEvent;

  bool _loading = false;
  TaskItem? _existingTask;

  TasksRepository get _repo => AppServices.I.tasksRepo;
  bool get _isEdit => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final t = await _repo.getById(widget.taskId!);
    if (!mounted) return;

    if (t != null) {
      _existingTask = t;
      _title.text = t.title;
      _notes.text = t.notes ?? '';
      _target = t.targetType;

      if (t.dayKey != null) _pickedDay = _fromDayKey(t.dayKey!);

      _pickedEventId = t.eventId;
      if (_pickedEventId != null) {
        _pickedEvent = await AppServices.I.eventsRepo.getById(_pickedEventId!);
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  String get _dayKey => _toDayKey(_pickedDay);

  Future<void> _pickEvent() async {
    final picked = await context.push<CalendarEvent>(
      AppRoutes.pickEvent,
      extra: _toDayKey(DateTime.now()),
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _target = TaskTargetType.event;
        _pickedEvent = picked;
        _pickedEventId = picked.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    final todayKey = _toDayKey(DateTime.now());
    
    return Stack(
      children: [
        const _NewEntryBackground(),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 120 + keyboard),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                _TopBar(
                  title: _isEdit ? 'Editar Tarea' : 'Crear Tarea',
                  onClose: () => context.pop(),
                ),
                const SizedBox(height: 14),

                _ModeToggle(
                  leftTitle: 'EVENTO',
                  rightTitle: 'TAREA',
                  selectedRight: true,
                  onLeftTap: () => context.push(AppRoutes.eventNew),
                ),

                const SizedBox(height: 18),

                _Label('TÍTULO'),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _title,
                  hint: '¿Qué necesitas hacer?',
                ),

                const SizedBox(height: 18),
                _Label('ASOCIAR A…'),
                const SizedBox(height: 10),

                _AssocToggle(
                  value: _target,
                  onChange: (v) {
                    setState(() {
                      _target = v;
                      if (v != TaskTargetType.event) {
                        _pickedEvent = null;
                        _pickedEventId = null;
                      }
                    });
                  },
                ),

                const SizedBox(height: 14),

                _loading
                    ? const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _AssocPanel(
                        target: _target,
                        pickedDay: _pickedDay,
                        onDayChanged: (d) => setState(() => _pickedDay = d),
                        dayKeyForEvents: todayKey,
                        pickedEvent: _pickedEvent,
                        onSelectEvent: (e) {
                          setState(() {
                            _target = TaskTargetType.event;
                            _pickedEvent = e;
                            _pickedEventId = e.id;
                          });
                        },
                        onViewAll: _pickEvent,
                      ),

                const SizedBox(height: 14),
                _PrimaryButton(
                  label: _isEdit ? 'GUARDAR CAMBIOS' : 'GUARDAR TAREA',
                  onTap: _save,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 10),
                  _DangerButton(
                    label: 'ELIMINAR TAREA',
                    onTap: _delete,
                  ),
                ],
                const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final id = widget.taskId ?? const Uuid().v4();
    final wasDone = _existingTask?.isDone ?? false;
    final createdAt = _existingTask?.createdAt ?? now;

    final dayKey = _target == TaskTargetType.day ? _dayKey : null;
    final eventId = _target == TaskTargetType.event ? _pickedEventId : null;

    final task = TaskItem(
      id: id,
      title: title,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      targetType: _target,
      dayKey: dayKey,
      eventId: eventId,
      isDone: wasDone,
      createdAt: createdAt,
      updatedAt: now,
    );

    await _repo.upsert(task);

    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.taskId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar tarea'),
        content: const Text('¿Seguro que quieres eliminar esta tarea? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok != true) return;
    await _repo.delete(id);

    if (!mounted) return;
    context.pop();
  }

  static String _toDayKey(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$mm-$dd';
  }

  static DateTime _fromDayKey(String dayKey) {
    final p = dayKey.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}

class _NewEntryBackground extends StatelessWidget {
  const _NewEntryBackground();

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
              opacity: 0.10,
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
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accentViolet.withOpacity(0.20), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _TopBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderTop),
            ),
            child: Icon(Icons.close, color: AppColors.textMuted2.withOpacity(0.9)),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String leftTitle;
  final String rightTitle;
  final bool selectedRight;
  final VoidCallback onLeftTap;

  const _ModeToggle({
    required this.leftTitle,
    required this.rightTitle,
    required this.selectedRight,
    required this.onLeftTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BigTile(
            title: leftTitle,
            icon: Icons.event,
            selected: !selectedRight,
            onTap: onLeftTap,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BigTile(
            title: rightTitle,
            icon: Icons.check_circle,
            selected: selectedRight,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _BigTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BigTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.accentViolet.withOpacity(0.75) : AppColors.borderTop;
    final bg = selected ? AppColors.deepViolet.withOpacity(0.35) : AppColors.surface.withOpacity(0.22);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentViolet.withOpacity(0.22) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.accentViolet : AppColors.textMuted2.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textMuted2.withOpacity(0.85),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted2.withOpacity(0.75),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _GlassField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderTop),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMuted2.withOpacity(0.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AssocToggle extends StatelessWidget {
  final TaskTargetType value;
  final ValueChanged<TaskTargetType> onChange;

  const _AssocToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallTile(
            title: 'DÍA',
            icon: Icons.calendar_month,
            selected: value == TaskTargetType.day,
            onTap: () => onChange(TaskTargetType.day),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallTile(
            title: 'EVENTO',
            icon: Icons.layers,
            selected: value == TaskTargetType.event,
            onTap: () => onChange(TaskTargetType.event),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallTile(
            title: 'SIN FECHA',
            icon: Icons.crop_square,
            selected: value == TaskTargetType.free,
            onTap: () => onChange(TaskTargetType.free),
          ),
        ),
      ],
    );
  }
}

class _SmallTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SmallTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.accentViolet.withOpacity(0.75) : AppColors.borderTop;
    final bg = selected ? AppColors.deepViolet.withOpacity(0.35) : AppColors.surface.withOpacity(0.22);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.accentViolet : AppColors.textMuted2.withOpacity(0.7)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textMuted2.withOpacity(0.8),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssocPanel extends StatelessWidget {
  final TaskTargetType target;
  final DateTime pickedDay;
  final ValueChanged<DateTime> onDayChanged;

  final String dayKeyForEvents;               // ✅ nuevo
  final CalendarEvent? pickedEvent;
  final ValueChanged<CalendarEvent> onSelectEvent; // ✅ nuevo
  final VoidCallback onViewAll;               // ✅ nuevo

  const _AssocPanel({
    required this.target,
    required this.pickedDay,
    required this.onDayChanged,
    required this.dayKeyForEvents,
    required this.pickedEvent,
    required this.onSelectEvent,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (target == TaskTargetType.free) {
      return const _InfoBanner(
        text: 'Esta tarea será guardada como LIBRE. Podrás asignarla a un momento específico más tarde.',
      );
    }

    if (target == TaskTargetType.day) {
      return _CalendarCard(
        selected: pickedDay,
        onChanged: onDayChanged,
      );
    }

    // target == event
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EVENTOS HOY',
              style: TextStyle(
                color: AppColors.textMuted2.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onViewAll,
              child: Text(
                'Ver todos',
                style: TextStyle(
                  color: AppColors.accentViolet.withOpacity(0.95),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _EventPreviewList(
            dayKey: dayKeyForEvents,
            selectedId: pickedEvent?.id,
            onSelect: onSelectEvent,
            onViewAll: onViewAll,
          ),
        ),
      ],
    );
  }
}

class _EventPreviewList extends StatelessWidget {
  final String dayKey;
  final String? selectedId;
  final ValueChanged<CalendarEvent> onSelect;
  final VoidCallback onViewAll;

  const _EventPreviewList({
    required this.dayKey,
    required this.selectedId,
    required this.onSelect,
    required this.onViewAll,
  });

  static String _fmtMin(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CalendarEvent>>(
      future: AppServices.I.eventsRepo.listByDayKey(dayKey),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snap.data ?? const [];

        if (events.isEmpty) {
          return InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderTop),
              ),
              child: Center(
                child: Text(
                  'No hay eventos para hoy.\nToca para ver/crear.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted2.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final e = events[i];
            final isSelected = e.id == selectedId;
            final color = Color(e.color);

            final subtitle = (e.startMin == null)
                ? 'Sin hora'
                : '${_fmtMin(e.startMin!)} - ${_fmtMin(e.endMin ?? (e.startMin! + 60))}';

            return InkWell(
              onTap: () => onSelect(e),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.deepViolet.withOpacity(0.35)
                      : AppColors.surface.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentViolet.withOpacity(0.7)
                        : AppColors.borderTop,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Icon(Icons.event, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textMuted2.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.accentViolet.withOpacity(0.95)
                          : AppColors.textMuted2.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _CalendarCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.22),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderTop),
      ),
      padding: const EdgeInsets.all(14),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accentViolet,
                onPrimary: Colors.white,
                surface: Colors.transparent,
                onSurface: AppColors.textPrimary,
              ),
        ),
        child: CalendarDatePicker(
          initialDate: selected,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          onDateChanged: onChanged,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderTop),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textMuted2.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMuted2.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
            ),
          ),
        ),
      ),
    );
  }
}


class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x66FF4D6D)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF6B81),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
            ),
          ),
        ),
      ),
    );
  }
}
