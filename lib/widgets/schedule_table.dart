import 'package:flutter/material.dart';
import '../models/program.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ScheduleTable extends StatefulWidget {
  final List<Program> programs;
  final String? weekLabel;

  const ScheduleTable({super.key, required this.programs, this.weekLabel});

  @override
  State<ScheduleTable> createState() => _ScheduleTableState();
}

class _ScheduleTableState extends State<ScheduleTable> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  late List<String> days;
  late List<String> hours;
  late Map<String, Map<String, Program>> scheduleMap;
  late bool isCurrentWeek;
  late String currentWeekLabel;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pl').then((_) {
      _prepareData();
      _checkIfCurrentWeek();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      setState(() => _isReady = true); // Trigger rebuild when ready
    });
  }

  void _prepareData() {
    days = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];

    hours = widget.programs.map((p) => p.hour).toSet().toList()..sort();

    scheduleMap = <String, Map<String, Program>>{};
    for (var hour in hours) {
      scheduleMap[hour] = {};
    }
    for (var p in widget.programs) {
      scheduleMap[p.hour]?[p.day] = p;
    }
  }

  void _checkIfCurrentWeek() {
    final now = DateTime.now();
    try {
      final weekNumber = ((now.difference(DateTime(now.year, 1, 4)).inDays + DateTime(now.year, 1, 4).weekday) / 7).ceil();
      currentWeekLabel = weekNumber % 2 == 0 ? 'Tydzień A' : 'Tydzień B';

      debugPrint('📅 weekNumber: $weekNumber');
      debugPrint('📅 currentWeekLabel: $currentWeekLabel');

      final effectiveWeek = widget.weekLabel ?? currentWeekLabel;
      debugPrint('📅 widget.weekLabel: $effectiveWeek');

      isCurrentWeek = effectiveWeek == currentWeekLabel;
      debugPrint('📅 isCurrentWeek: $isCurrentWeek');
    } catch (e) {
      debugPrint('⚠️ Week check error: $e');
      isCurrentWeek = false;
    }
  }

  void _scrollToCurrent() {
    if (!isCurrentWeek) return;
    final now = DateTime.now();
    final hour = DateFormat('HH:00').format(now);
    final hourIndex = hours.indexOf(hour);

    if (hourIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_vertical.hasClients && _vertical.position.hasContentDimensions) {
          final offset = hourIndex * 72.0;
          if (offset <= _vertical.position.maxScrollExtent) {
            _vertical.animateTo(
              offset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final currentHour = DateFormat('HH:00').format(now);
    final currentDay = days[now.weekday - 1];
    debugPrint('🕒 now: $now → currentHour: $currentHour, currentDay: $currentDay');

    final totalWidth = MediaQuery.of(context).size.width;
    final tableWidth = 80.0 + (days.length * 140);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: totalWidth,
              color: Colors.indigo[50],
              child: Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Godzina',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ...days.map(
                        (day) => Container(
                      width: 140,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: hours.length,
                      itemBuilder: (context, rowIndex) {
                        final hour = hours[rowIndex];
                        final isCurrentHour = isCurrentWeek && hour == currentHour;
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 80,
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.topLeft,
                                color: isCurrentHour ? Colors.yellow[100] : null,
                                child: Text(
                                  hour,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentHour ? Colors.indigo : Colors.black,
                                  ),
                                ),
                              ),
                              ...days.map((day) {
                                final program = scheduleMap[hour]?[day];
                                final isNow = isCurrentWeek && hour == currentHour && day == currentDay;
                                debugPrint('➡️ $hour – $day → highlight: $isNow');
                                return Container(
                                  width: 140,
                                  padding: const EdgeInsets.all(8),
                                  color: isNow ? Colors.yellow.withOpacity(0.3) : null,
                                  child: program != null
                                      ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        program.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                      if (program.host != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            program.host!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                    ],
                                  )
                                      : const SizedBox(),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
