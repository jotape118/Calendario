import 'package:flutter/material.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';

class CalendarVoiceApp extends StatelessWidget {
  const CalendarVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: buildRouter(),
    );
  }
}
