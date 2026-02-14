import 'package:flutter/material.dart';

class PickDayScreen extends StatefulWidget {
  const PickDayScreen({super.key});

  @override
  State<PickDayScreen> createState() => _PickDayScreenState();
}

class _PickDayScreenState extends State<PickDayScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asociar a Día')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selected,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text('Seleccionar día'),
            ),
          ),
        ],
      ),
    );
  }
}
