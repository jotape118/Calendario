import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key});

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  bool listening = true;
  bool processing = true;
  String transcript = '“Comprar leche mañana”';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        const _CaptureBackground(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 120 + bottomInset),
            child: Column(
              children: [
                Row(
                  children: [
                    _TopPillButton(
                      icon: Icons.keyboard_arrow_down,
                      label: 'Marzo 12',
                      onTap: () {},
                    ),
                    const Spacer(),
                    _CircleIconButton(icon: Icons.settings, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: AppColors.borderTop),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF243757),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4A57),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                listening ? 'CAPTURANDO AUDIO' : 'LISTO PARA ESCUCHAR',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const _WaveBars(),
                          const SizedBox(height: 40),
                          Text(
                            transcript,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.95),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _AiContextCard(processing: processing),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  dark: true,
                                  icon: Icons.close,
                                  label: 'DESCARTAR',
                                  onTap: () => setState(() {
                                    transcript = '';
                                    listening = false;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  dark: false,
                                  icon: Icons.check_circle,
                                  label: 'CONFIRMAR',
                                  onTap: () => setState(() {
                                    processing = false;
                                    listening = false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptureBackground extends StatelessWidget {
  const _CaptureBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFF07070A)],
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
                      colors: [AppColors.w(0.0), AppColors.w(0.09), AppColors.w(0.0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopPillButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.24),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderTop),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.88),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.textMuted2),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.24),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderTop),
        ),
        child: Icon(icon, color: AppColors.textMuted2, size: 30),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars();

  @override
  Widget build(BuildContext context) {
    const heights = <double>[36.0, 58.0, 72.0, 52.0, 78.0, 54.0, 70.0, 46.0, 30.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(heights.length, (i) {
        final opacity = 0.25 + (i / heights.length) * 0.75;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 8,
            height: heights[i],
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withOpacity(opacity),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _AiContextCard extends StatelessWidget {
  final bool processing;
  const _AiContextCard({required this.processing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepViolet.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.accentViolet.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accentViolet.withOpacity(0.95), size: 18),
              const SizedBox(width: 8),
              Text(
                'CONTEXTO IA',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accentViolet.withOpacity(0.6)),
                ),
                child: Text(
                  processing ? 'PROCESANDO' : 'LISTO',
                  style: TextStyle(
                    color: AppColors.accentViolet.withOpacity(0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentViolet.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: const Icon(Icons.shopping_cart, color: AppColors.accentViolet),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUGERENCIA',
                      style: TextStyle(
                        color: AppColors.textMuted2.withOpacity(0.95),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Nueva tarea en 'Compras'",
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.dark, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: dark ? AppColors.surface.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: dark ? Border.all(color: AppColors.borderTop) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? AppColors.textMuted2 : Colors.black),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: dark ? AppColors.textPrimary.withOpacity(0.92) : Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
