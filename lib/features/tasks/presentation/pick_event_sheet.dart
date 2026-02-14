import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../event/domain/entities/calendar_event.dart';

class PickEventSheet extends StatefulWidget {
  final String dayKey; // YYYY-MM-DD
  const PickEventSheet({super.key, required this.dayKey});

  @override
  State<PickEventSheet> createState() => _PickEventSheetState();
}

class _PickEventSheetState extends State<PickEventSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _fmtMin(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Asociar a Evento'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderTop),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Buscar evento...',
                  hintStyle: TextStyle(color: AppColors.textMuted2.withOpacity(0.6)),
                  icon: Icon(Icons.search, color: AppColors.textMuted2.withOpacity(0.7)),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<CalendarEvent>>(
                future: AppServices.I.eventsRepo.listByDayKey(widget.dayKey),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final q = _search.text.trim().toLowerCase();
                  final all = snap.data ?? const [];
                  final items = q.isEmpty
                      ? all
                      : all.where((e) => e.title.toLowerCase().contains(q)).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        q.isEmpty ? 'No hay eventos para este día.' : 'No hay resultados.',
                        style: TextStyle(color: AppColors.textMuted2.withOpacity(0.7)),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final color = Color(e.color);

                      final subtitle = (e.startMin == null)
                          ? 'Sin hora'
                          : '${_fmtMin(e.startMin!)} - ${_fmtMin(e.endMin ?? (e.startMin! + 60))}';

                      return InkWell(
                        onTap: () => context.pop<CalendarEvent>(e),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderTop),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
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
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: AppColors.textMuted2.withOpacity(0.85),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: AppColors.textMuted2.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
