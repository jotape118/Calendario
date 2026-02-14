import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/calendar_event.dart';

class EventEditScreen extends StatefulWidget {
  final String? eventId;
  const EventEditScreen._({this.eventId});

  const EventEditScreen.newEvent({super.key}) : eventId = null;
  const EventEditScreen.edit({super.key, required String eventId})
      : eventId = eventId;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay? _start;
  TimeOfDay? _end;

  int _colorValue = AppColors.accentViolet.value;

  DateTime? _createdAt;
  bool _loading = false;

  bool get _isEdit => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    _hydrateIfEdit();
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _hydrateIfEdit() async {
    final id = widget.eventId;
    if (id == null) return;

    setState(() => _loading = true);
    final e = await AppServices.I.eventsRepo.getById(id);
    if (!mounted) return;

    if (e != null) {
      _title.text = e.title;
      _notes.text = e.notes ?? '';
      _date = _parseDayKey(e.dayKey);
      _start = e.startMin == null ? null : _minToTimeOfDay(e.startMin!);
      _end = e.endMin == null ? null : _minToTimeOfDay(e.endMin!);
      _colorValue = e.color;
      _createdAt = e.createdAt;
    }
    setState(() => _loading = false);
  }

  void _safeClose() {
    final r = GoRouter.of(context);
    if (r.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.day);
    }
  }

  Future<void> _pickDateTime() async {
    final res = await showModalBottomSheet<_DateTimeResult>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _DateTimeSheet(
        initialDate: _date,
        initialStart: _start,
        initialEnd: _end,
      ),
    );

    if (!mounted) return;
    if (res == null) return;

    setState(() {
      _date = res.date;
      _start = res.start;
      _end = res.end;

      // Si hay inicio y no hay fin -> default +90min para que se vea como rango (mock)
      if (_start != null) {
        final s = _start!.hour * 60 + _start!.minute;
        final e = _end == null ? null : (_end!.hour * 60 + _end!.minute);

        final fixedEndMin = _ensureEndAfterStart(s, e);
        _end = fixedEndMin == null ? null : _minToTimeOfDay(fixedEndMin);
      } else {
        _end = null; // sin hora => sin fin
      }
    });
  }

  Future<void> _pickColor() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _ColorPickerSheet(selected: _colorValue),
    );

    if (!mounted) return;
    if (picked != null) setState(() => _colorValue = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título al evento')),
      );
      return;
    }

    final startMin = _start == null ? null : (_start!.hour * 60 + _start!.minute);
    final endMinRaw = _end == null ? null : (_end!.hour * 60 + _end!.minute);

    // Regla: si hay start, ajustamos fin para que siempre sea mayor (default +90)
    final endMin = startMin == null ? null : _ensureEndAfterStart(startMin, endMinRaw);

    if (startMin == null && endMinRaw != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si pones hora de fin, debes poner hora de inicio')),
      );
      return;
    }

    final now = DateTime.now();
    final dayKey = _toDayKey(_date);
    final id = widget.eventId ?? const Uuid().v4();

    final event = CalendarEvent(
      id: id,
      dayKey: dayKey,
      title: title,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      startMin: startMin,
      endMin: endMin,
      color: _colorValue,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );

    await AppServices.I.eventsRepo.upsert(event);
    await AppServices.I.dayController.load();

    if (!mounted) return;
    _safeClose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        const _EntryBackground(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset + 120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                children: [
                  _TopBar(
                    title: _isEdit ? 'Editar Evento' : 'Crear Evento',
                    onClose: _safeClose,
                  ),
                  const SizedBox(height: 14),

                  // Selector EVENTO/TAREA (mock)
                  _ModeToggle(
                    leftTitle: 'EVENTO',
                    rightTitle: 'TAREA',
                    selectedLeft: true,
                    onRightTap: () => context.push(AppRoutes.taskNew),
                  ),

                  const SizedBox(height: 18),

                  _Label('TÍTULO'),
                  const SizedBox(height: 8),
                  _GlassField(
                    controller: _title,
                    hint: '¿Qué tienes en mente?',
                  ),

                  const SizedBox(height: 18),

                  _Label('FECHA Y HORA'),
                  const SizedBox(height: 8),
                  _DateTimePill(
                    label: _dateTimeLabel(context),
                    onTap: _pickDateTime,
                  ),

                  const SizedBox(height: 14),

                  // Color compacto (opcional)
                  _Label('COLOR'),
                  const SizedBox(height: 10),
                  _ColorRow(
                    selected: _colorValue,
                    onPick: (v) => setState(() => _colorValue = v),
                    onMore: _pickColor,
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _NotesSection(
                            controller: _notes,
                          ),
                  ),

                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'GUARDAR',
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dateTimeLabel(BuildContext context) {
    final prefix = _humanDay(_date);
    if (_start == null) return '$prefix, Sin hora';
    final start = _start!.format(context);
    // En mock muestran solo start, pero dejamos rango si hay fin
    if (_end == null) return '$prefix, $start';
    final end = _end!.format(context);
    return '$prefix, $start — $end';
  }

  static int? _ensureEndAfterStart(int startMin, int? endMin) {
    // Default fin +90 min (mock de rangos)
    final def = (startMin + 90).clamp(0, 1439);
    if (endMin == null) return def;
    if (endMin <= startMin) return def;
    return endMin;
  }

  static String _humanDay(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(d.year, d.month, d.day);

    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';

    // fallback corto: "22 OCT"
    const mons = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    return '${b.day} ${mons[b.month - 1]}';
  }

  static String _toDayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime _parseDayKey(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static TimeOfDay _minToTimeOfDay(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    return TimeOfDay(hour: h, minute: m);
  }
}

/* ========================= UI ========================= */

class _EntryBackground extends StatelessWidget {
  const _EntryBackground();

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
            left: -80,
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
            fontSize: 22,
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
  final bool selectedLeft;
  final VoidCallback onRightTap;

  const _ModeToggle({
    required this.leftTitle,
    required this.rightTitle,
    required this.selectedLeft,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BigTile(
            title: leftTitle,
            icon: Icons.event,
            selected: selectedLeft,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BigTile(
            title: rightTitle,
            icon: Icons.check_circle,
            selected: !selectedLeft,
            onTap: onRightTap,
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
    final border = selected
        ? AppColors.accentViolet.withOpacity(0.75)
        : AppColors.borderTop;

    final bg = selected
        ? AppColors.deepViolet.withOpacity(0.35)
        : AppColors.surface.withOpacity(0.22);

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
                  color: selected
                      ? AppColors.accentViolet.withOpacity(0.22)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.accentViolet
                      : AppColors.textMuted2.withOpacity(0.8),
                  size: 22,
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

class _DateTimePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateTimePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderTop),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.calendar_month, color: AppColors.textMuted2.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onPick;
  final VoidCallback onMore;

  const _ColorRow({
    required this.selected,
    required this.onPick,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final palette = <Color>[
      AppColors.accentViolet,
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFE11D48),
    ];

    return Row(
      children: [
        ...palette.take(6).map((c) {
          final isSelected = c.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onPick(c.value),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.borderTop,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        InkWell(
          onTap: onMore,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderTop),
            ),
            child: Icon(Icons.palette_outlined, color: AppColors.textMuted2.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }
}

class _NotesSection extends StatefulWidget {
  final TextEditingController controller;
  const _NotesSection({required this.controller});

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: open
          ? Column(
              key: const ValueKey('open'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NOTAS (OPCIONAL)',
                      style: TextStyle(
                        color: AppColors.textMuted2.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => open = false),
                      icon: const Icon(Icons.expand_less),
                      color: AppColors.textMuted2.withOpacity(0.8),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderTop),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: widget.controller,
                    minLines: 4,
                    maxLines: 8,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe notas si quieres…',
                      hintStyle: TextStyle(color: AppColors.textMuted2.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              key: const ValueKey('closed'),
              onTap: () => setState(() => open = true),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderTop),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.notes, color: AppColors.textMuted2.withOpacity(0.75)),
                    const SizedBox(width: 10),
                    Text(
                      'Agregar notas (opcional)',
                      style: TextStyle(
                        color: AppColors.textMuted2.withOpacity(0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more, color: AppColors.textMuted2.withOpacity(0.75)),
                  ],
                ),
              ),
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

/* ========================= SHEETS ========================= */

class _DateTimeResult {
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  const _DateTimeResult({required this.date, required this.start, required this.end});
}

class _DateTimeSheet extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;

  const _DateTimeSheet({
    required this.initialDate,
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_DateTimeSheet> createState() => _DateTimeSheetState();
}

class _DateTimeSheetState extends State<_DateTimeSheet> {
  late DateTime date;
  TimeOfDay? start;
  TimeOfDay? end;

  @override
  void initState() {
    super.initState();
    date = widget.initialDate;
    start = widget.initialStart;
    end = widget.initialEnd;
  }

  bool get noTime => start == null;

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    setState(() {
      start = picked;

      // default end +90
      final sMin = picked.hour * 60 + picked.minute;
      final eMin = (sMin + 90).clamp(0, 1439);
      end = TimeOfDay(hour: eMin ~/ 60, minute: eMin % 60);
    });
  }

  Future<void> _pickEnd() async {
    if (start == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: end ?? start!,
    );
    if (picked == null) return;

    setState(() => end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderTop,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fecha y hora',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderTop),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.textMuted2.withOpacity(0.8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        noTime ? 'Sin hora' : 'Con hora',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Switch(
                      value: !noTime,
                      onChanged: (v) {
                        setState(() {
                          if (!v) {
                            start = null;
                            end = null;
                          } else {
                            final now = TimeOfDay.now();
                            start = now;
                            final s = now.hour * 60 + now.minute;
                            final e = (s + 90).clamp(0, 1439);
                            end = TimeOfDay(hour: e ~/ 60, minute: e % 60);
                          }
                        });
                      },
                      activeColor: AppColors.accentViolet,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderTop),
                ),
                padding: const EdgeInsets.all(10),
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
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    onDateChanged: (d) => setState(() => date = d),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (!noTime) ...[
                Row(
                  children: [
                    Expanded(
                      child: _TimePill(
                        label: 'Inicio',
                        value: start?.format(context) ?? '--:--',
                        onTap: _pickStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePill(
                        label: 'Fin',
                        value: end?.format(context) ?? '--:--',
                        onTap: _pickEnd,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderTop),
                        ),
                        child: Center(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: AppColors.textMuted2.withOpacity(0.9),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        _DateTimeResult(date: date, start: start, end: end),
                      ),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accentViolet.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'Listo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderTop),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.textMuted2.withOpacity(0.75)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textMuted2.withOpacity(0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
}

class _ColorPickerSheet extends StatelessWidget {
  final int selected;
  const _ColorPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = <Color>[
      AppColors.accentViolet,
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFE11D48),
      const Color(0xFFA78BFA),
      const Color(0xFF94A3B8),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderTop,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecciona un color',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: palette.map((c) {
                final isSelected = c.value == selected;
                return InkWell(
                  onTap: () => Navigator.pop(context, c.value),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : AppColors.borderTop,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
