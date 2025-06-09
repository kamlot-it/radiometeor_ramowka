import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/program.dart';
import '../../data/services/google_sheet_service.dart';

enum ScheduleState { initial, loading, loaded, error, refreshing }

class ScheduleProvider extends ChangeNotifier {
  ScheduleState _state = ScheduleState.initial;
  List<Program> _programs = [];
  String _selectedWeek = 'Tydzień B'; // Domyślnie Tydzień B
  late String _selectedDay; // Aktualnie wybrany dzień tygodnia
  late String _currentWeek; // Obliczony tydzień dla zaznaczania "na żywo"
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _isInitialized = false;

  // Getters
  ScheduleState get state => _state;
  List<Program> get programs => _programs;
  String get selectedWeek => _selectedWeek; // Przywrócone selectedWeek
  String get selectedDay => _selectedDay;
  String get currentWeek => _currentWeek;
  bool get isCurrentWeekSelected => _selectedWeek == _currentWeek;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isInitialized => _isInitialized;

  // Dostępne tygodnie
  List<String> get availableWeeks => ['Tydzień A', 'Tydzień B'];
  List<String> get availableDays => [
        'Poniedziałek',
        'Wtorek',
        'Środa',
        'Czwartek',
        'Piątek',
        'Sobota',
        'Niedziela'
      ];

  // Computed properties
  Program? get currentProgram {
    if (!isCurrentWeekSelected) return null;
    return _programs
        .where((program) => program.isCurrentlyPlaying)
        .firstOrNull;
  }

  List<Program> get programsForSelectedDay {
    return _programs.where((p) => p.day == _selectedDay).toList();
  }

  List<Program> get todayPrograms {
    final today = _getCurrentDayName();
    return _programs.where((program) => program.day == today).toList();
  }

  List<Program> get upcomingPrograms {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final today = _getCurrentDayName();

    return _programs.where((program) {
      try {
        return program.day == today && program.startTime.compareTo(currentTime) > 0;
      } catch (e) {
        return false;
      }
    }).take(3).toList();
  }

  int get totalPrograms => _programs.length;

  String get totalDuration {
    if (_programs.isEmpty) return '0h 0min';

    int totalMinutes = 0;
    for (final program in _programs) {
      try {
        final startParts = program.startTime.split(':');
        final endParts = program.endTime.split(':');

        final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        totalMinutes += (endMinutes - startMinutes);
      } catch (e) {
        continue;
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}min';
  }

  bool isProgramCurrentlyPlaying(Program program) {
    return isCurrentWeekSelected && program.isCurrentlyPlaying;
  }

  String _getCurrentDayName() {
    final now = DateTime.now();
    const days = [
      'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek',
      'Piątek', 'Sobota', 'Niedziela'
    ];
    return days[now.weekday - 1];
  }

  ScheduleProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _calculateCurrentWeek(); // Ustal aktualny tydzień
    _selectedDay = _getCurrentDayName();
    await _loadCachedData();
    await loadSchedule();
    _isInitialized = true;
    notifyListeners();
  }

  // Przywrócona logika obliczania tygodnia A/B
  void _calculateCurrentWeek() {
    final now = DateTime.now();

    // Oblicz numer tygodnia roku
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(firstDayOfYear).inDays + 1;
    final weekNumber = (dayOfYear / 7).ceil();

    // Tydzień B dla parzystych, Tydzień A dla nieparzystych
    _currentWeek = weekNumber % 2 == 0 ? 'Tydzień B' : 'Tydzień A';

    debugPrint('📅 Obliczony tydzień: $_currentWeek (tydzień $weekNumber w roku)');
  }

  Future<void> loadSchedule({bool showLoading = true}) async {
    if (showLoading && _state != ScheduleState.refreshing) {
      _state = ScheduleState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      debugPrint('🔄 Ładowanie ramówki dla: $_selectedWeek');

      final programs = await GoogleSheetService.fetchSchedule(_selectedWeek);

      _programs = programs;
      _state = ScheduleState.loaded;
      _errorMessage = null;
      _lastUpdated = DateTime.now();

      await _cacheData();

      debugPrint('✅ Załadowano ${_programs.length} programów');

    } catch (e) {
      _state = ScheduleState.error;
      _errorMessage = e.toString();

      debugPrint('❌ Błąd ładowania ramówki: $e');

      if (_programs.isEmpty) {
        await _loadCachedData();
      }
    }

    notifyListeners();
  }

  Future<void> changeWeek(String week) async {
    if (week != _selectedWeek) {
      _selectedWeek = week;
      await _saveSetting('selectedWeek', week);
      await loadSchedule();

      debugPrint('📅 Zmieniono tydzień na: $_selectedWeek');
    }
  }

  Future<void> changeDay(String day) async {
    if (availableDays.contains(day) && day != _selectedDay) {
      _selectedDay = day;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _state = ScheduleState.refreshing;
    notifyListeners();

    await loadSchedule(showLoading: false);
  }

  // Cache management
  Future<void> _cacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'schedule_${_selectedWeek.replaceAll(' ', '_')}';

      final cacheData = {
        'programs': _programs.map((p) => p.toJson()).toList(),
        'lastUpdated': _lastUpdated?.millisecondsSinceEpoch,
        'week': _selectedWeek,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('💾 Dane zapisane w cache dla: $_selectedWeek');

    } catch (e) {
      debugPrint('❌ Błąd zapisywania cache: $e');
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _selectedWeek = prefs.getString('selectedWeek') ?? _currentWeek;

      final cacheKey = 'schedule_${_selectedWeek.replaceAll(' ', '_')}';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null) {
        final cacheData = json.decode(cachedJson);
        final programsJson = cacheData['programs'] as List<dynamic>?;

        if (programsJson != null) {
          _programs = programsJson.map((json) => Program.fromJson(json)).toList();

          final lastUpdatedMs = cacheData['lastUpdated'] as int?;
          if (lastUpdatedMs != null) {
            _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs);
          }

          debugPrint('📱 Załadowano ${_programs.length} programów z cache');
        }
      }

    } catch (e) {
      debugPrint('❌ Błąd ładowania cache: $e');
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ Błąd zapisywania ustawienia $key: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('schedule_')).toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🗑️ Cache wyczyszczony');

    } catch (e) {
      debugPrint('❌ Błąd czyszczenia cache: $e');
    }
  }

  Future<bool> testConnection() async {
    return await GoogleSheetService.testConnection();
  }

  @override
  void dispose() {
    debugPrint('🔄 ScheduleProvider disposed');
    super.dispose();
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}

void debugPrint(String message) {
  if (kDebugMode) {
    print('[ScheduleProvider] $message');
  }
}
