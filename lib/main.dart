import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/google_sheet_service.dart';
import 'models/program.dart';
import 'widgets/schedule_table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ramówka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String selectedWeek;
  late Future<List<Program>> futureSchedule;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final firstThursday = DateTime(now.year, 1, 4);
    final weekNumber =
    ((now.difference(firstThursday).inDays + firstThursday.weekday) / 7).ceil();

    selectedWeek = weekNumber % 2 == 0 ? 'Tydzień A' : 'Tydzień B';

    futureSchedule = GoogleSheetService.fetchSchedule(selectedWeek);
  }

  void _onWeekChange(String week) {
    setState(() {
      selectedWeek = week;
      futureSchedule = GoogleSheetService.fetchSchedule(week);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ramówka – $selectedWeek'),
        actions: [
          DropdownButton<String>(
            value: selectedWeek,
            dropdownColor: Colors.white,
            underline: Container(),
            items: ['Tydzień A', 'Tydzień B']
                .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                .toList(),
            onChanged: (val) {
              if (val != null) _onWeekChange(val);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Program>>(
        future: futureSchedule,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

          final programs = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScheduleTable(
              programs: programs,
              weekLabel: selectedWeek, // 🔥 Important!
            ),
          );
        },
      ),
    );
  }
}
