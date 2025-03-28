import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/program.dart';

class GoogleSheetService {
  static const List<String> daysOfWeek = [
    'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela',
  ];

  static const sheetUrls = {
    'Tydzień A': 'https://docs.google.com/spreadsheets/d/1nx3iG3qNFwYSr0Uj44M8OPZKliKeLz0R8s6QzJU22ao/gviz/tq?tqx=out:csv&sheet=Tydzień A',
    'Tydzień B': 'https://docs.google.com/spreadsheets/d/1nx3iG3qNFwYSr0Uj44M8OPZKliKeLz0R8s6QzJU22ao/gviz/tq?tqx=out:csv&sheet=Tydzień B',
  };

  static Future<List<Program>> fetchSchedule(String week) async {
    final url = sheetUrls[week];
    if (url == null) throw Exception('Invalid week: $week');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to load sheet: $week');

    final csvRaw = const Utf8Decoder().convert(response.bodyBytes);
    final csvData = const CsvToListConverter().convert(csvRaw, eol: '\n');

    final headers = csvData.first.cast<String>();
    final godzinaIndex = headers.indexWhere((h) => h.trim().toLowerCase() == 'godzina');

    if (godzinaIndex == -1) {
      throw ('nie znaleziono kolumny "Godzina" w arkuszu.');
    };

    List<Program> schedule = [];

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      final hour = row[godzinaIndex].toString();

      for (int j = godzinaIndex + 1; j < headers.length; j++) {
        final day = headers[j];
        final cell = row[j]?.toString().trim();

        if (cell != null && cell.isNotEmpty) {
          String title = cell;
          String? host;

          // Optional host detection (split by dash, e.g. "Program – Host")
          if (cell.contains('–')) {
            final parts = cell.split('–');
            title = parts[0].trim();
            host = parts.length > 1 ? parts[1].trim() : null;
          }

          schedule.add(Program(
            day: day,
            hour: hour,
            title: title,
            host: host,
          ));
        }
      }
    }

    return schedule;
  }
}
