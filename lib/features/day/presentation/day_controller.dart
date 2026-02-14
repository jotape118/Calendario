import 'package:flutter/foundation.dart';
import '../../event/domain/entities/calendar_event.dart';
import '../../event/domain/repositories/events_repository.dart';

class DayController extends ChangeNotifier {
  final EventsRepository _eventsRepo;

  DayController(this._eventsRepo);

  DateTime _selectedDay = DateTime.now();
  List<CalendarEvent> _events = [];
  bool _loading = false;

  DateTime get selectedDay => _selectedDay;
  List<CalendarEvent> get events => _events;
  bool get loading => _loading;

  String get dayKey => _toDayKey(_selectedDay);

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _events = await _eventsRepo.listByDayKey(dayKey);
    _loading = false;
    notifyListeners();
  }

  Future<void> setDay(DateTime d) async {
    _selectedDay = DateTime(d.year, d.month, d.day);
    await load();
  }

  Future<void> prevDay() => setDay(_selectedDay.subtract(const Duration(days: 1)));
  Future<void> nextDay() => setDay(_selectedDay.add(const Duration(days: 1)));

  static String _toDayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
