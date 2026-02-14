import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../../core/theme/app_colors.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  int _indexFromLocation(BuildContext context) {
  final loc = GoRouterState.of(context).uri.toString();

  if (loc.startsWith(AppRoutes.tasks)) return 1;
  if (loc.startsWith('/task/') || loc.startsWith('/event/')) return 2;
  if (loc.startsWith(AppRoutes.micro) || loc.startsWith(AppRoutes.capture)) return 3;

  return 0; // day
}

  @override
  Widget build(BuildContext context) {
    final idx = _indexFromLocation(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: idx,
        onTapDay: () => context.go(AppRoutes.day),
        onTapTasks: () => context.go(AppRoutes.tasks),
        onTapNew: () => context.push(AppRoutes.taskNew),
        onTapMicro: () => context.go(AppRoutes.micro),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onTapDay;
  final VoidCallback onTapTasks;
  final VoidCallback onTapNew;
  final VoidCallback onTapMicro;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTapDay,
    required this.onTapTasks,
    required this.onTapNew,
    required this.onTapMicro,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barHeight = 74.0 + bottomInset;

    return SizedBox(
      height: barHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.only(left: 18, right: 96, bottom: bottomInset),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.92),
                border: const Border(top: BorderSide(color: AppColors.borderTop)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    label: 'DÍA',
                    icon: Icons.calendar_today_outlined,
                    selected: selectedIndex == 0,
                    onTap: onTapDay,
                  ),
                  _NavItem(
                    label: 'TAREAS',
                    icon: Icons.format_list_bulleted,
                    selected: selectedIndex == 1,
                    onTap: onTapTasks,
                  ),
                  _NavItem(
                    label: 'NUEVO',
                    icon: Icons.add_box_outlined,
                    selected: selectedIndex == 2,
                    onTap: onTapNew,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 18,
            bottom: bottomInset + 6,
            child: _MicroButton(
              selected: selectedIndex == 3,
              onTap: onTapMicro,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppColors.accentViolet : AppColors.textMuted2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _MicroButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppColors.accentViolet : AppColors.textMuted2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.accentViolet,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentViolet.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: const Center(
                  child: Icon(Icons.mic, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'MICRO',
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
