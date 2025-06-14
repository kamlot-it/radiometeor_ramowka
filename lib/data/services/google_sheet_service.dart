import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/program.dart';

class GoogleSheetService {
  static const sheetUrls = {
    'Tydzień A': 'https://docs.google.com/spreadsheets/d/1nx3iG3qNFwYSr0Uj44M8OPZKliKeLz0R8s6QzJU22ao/gviz/tq?tqx=out:csv&sheet=Tydzień A',
    'Tydzień B': 'https://docs.google.com/spreadsheets/d/1nx3iG3qNFwYSr0Uj44M8OPZKliKeLz0R8s6QzJU22ao/gviz/tq?tqx=out:csv&sheet=Tydzień B',
  };

  static Future<List<Program>> fetchSchedule(String week) async {
    final url = sheetUrls[week];
    if (url == null) throw Exception('Invalid week: $week');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load sheet');
    }

    final csvRaw = const Utf8Decoder().convert(response.bodyBytes);
    final csvData = const CsvToListConverter().convert(csvRaw, eol: '\n');

    if (csvData.isEmpty) return [];

    final headers = csvData.first.cast<String>();
    final godzinaIndex = headers.indexWhere((h) => h.trim().toLowerCase() == 'godzina');
    if (godzinaIndex == -1) {
      throw const FormatException('Brak kolumny Godzina w arkuszu');
    }

    final startTimes = <String>[];
    final rows = <List<dynamic>>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;
      startTimes.add(row[godzinaIndex].toString());
      rows.add(row);
    }

    final programs = <Program>[];
    final lastIndexByDay = <String, int>{};

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final startTime = startTimes[i];
      final endTime = i < startTimes.length - 1 ? startTimes[i + 1] : '00:00';

      for (int j = godzinaIndex + 1; j < headers.length; j++) {
        final day = headers[j];
        final cell = j < row.length ? row[j]?.toString().trim() : '';

        if (cell == null || cell.isEmpty) {
          final prevIndex = lastIndexByDay[day];
          if (prevIndex != null) {
            final prev = programs[prevIndex];
            // extend the previous program across this empty slot
            programs[prevIndex] = Program(
              day: prev.day,
              startTime: prev.startTime,
              endTime: endTime,
              title: prev.title,
              hosts: prev.hosts,
              categoryName: prev.categoryName,
              categoryColorHex: prev.categoryColorHex,
            );
          }
          continue;
        }

        var title = cell;
        String? hosts;
        if (cell.contains('–')) {
          final parts = cell.split('–');
          title = parts[0].trim();
          hosts = parts.length > 1 ? parts[1].trim() : null;
        }
        title = title.trim();
        hosts = hosts?.trim();

        final prevIndex = lastIndexByDay[day];
        if (prevIndex != null) {
          final prev = programs[prevIndex];
          final sameTitle = normalize(prev.title) == normalize(title);
          final sameHosts = (prev.hosts ?? '').trim() == (hosts ?? '').trim();
          if (sameTitle && sameHosts && prev.endTime == startTime) {
            programs[prevIndex] = Program(
              day: day,
              startTime: prev.startTime,
              endTime: endTime,
              title: prev.title,
              hosts: prev.hosts,
              categoryName: prev.categoryName,
              categoryColorHex: prev.categoryColorHex,
            );
            continue;
          }
        }

        final program = Program(
          day: day,
          startTime: startTime,
          endTime: endTime,
          title: title,
          hosts: hosts,
          categoryName: 'Program',
          categoryColorHex: '#FF6600',
        );
        programs.add(program);
        lastIndexByDay[day] = programs.length - 1;
      }
    }

    // Merge consecutive entries that represent the same program
    // so long shows like NOC spanning multiple hours appear once
    List<Program> merged = [];
    Program? last;
    String normalize(String input) =>
        input.toLowerCase().trim().replaceAll(RegExp(r'[–-]'), '-');

    for (final p in programs) {
      if (last != null &&
          last.day == p.day &&
          normalize(last.title) == normalize(p.title) &&
          (last.hosts ?? '').trim() == (p.hosts ?? '').trim() &&
          last.endTime == p.startTime) {
        last = Program(
          day: last.day,
          startTime: last.startTime,
          endTime: p.endTime,
          title: last.title,
          hosts: last.hosts,
          categoryName: last.categoryName,
          categoryColorHex: last.categoryColorHex,
        );
        merged[merged.length - 1] = last;
      } else {
        merged.add(p);
        last = p;
      }
    }

    return merged;
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse(sheetUrls.values.first));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
