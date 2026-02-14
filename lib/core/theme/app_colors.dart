import 'package:flutter/material.dart';

class AppColors {
  // Base
  static const background = Color(0xFF0A0A0C);
  static const surface = Color(0xFF121216);

  // Brand / Accent
  static const accentViolet = Color(0xFF8B5CF6);
  static const primary = Color(0xFF6D28D9);
  static const deepViolet = Color(0xFF4C1D95);

  // UI
  static const borderSoft = Color(0x14FFFFFF); // ~8% white
  static const borderTop = Color(0x0DFFFFFF); // ~5% white

  // Text
  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFF94A3B8);  // slate-400
  static const textMuted2 = Color(0xFF64748B); // slate-500

  // Helpers
  static Color w(double o) => Colors.white.withOpacity(o);
  static Color v(double o) => accentViolet.withOpacity(o);
}