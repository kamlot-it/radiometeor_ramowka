import 'package:flutter/material.dart';

class Program {
  final String day;
  final String startTime;
  final String endTime;
  final String title;
  final String? hosts;
  final String? description;
  final String categoryName;
  final String categoryColorHex;

  Program({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.hosts,
    this.description,
    this.categoryName = 'Program',
    this.categoryColorHex = '#FF6600',
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      title: json['title'] ?? '',
      hosts: json['hosts'],
      description: json['description'],
      categoryName: json['categoryName'] ?? 'Program',
      categoryColorHex: json['categoryColorHex'] ?? '#FF6600',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'title': title,
      'hosts': hosts,
      'description': description,
      'categoryName': categoryName,
      'categoryColorHex': categoryColorHex,
    };
  }

  Color get categoryColor {
    final hex = categoryColorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String get timeRange => '$startTime - $endTime';

  String get duration {
    try {
      final startParts = startTime.split(':').map(int.parse).toList();
      final endParts = endTime.split(':').map(int.parse).toList();
      final start = Duration(hours: startParts[0], minutes: startParts[1]);
      final end = Duration(hours: endParts[0], minutes: endParts[1]);
      var diff = end - start;
      if (diff.isNegative) diff += const Duration(days: 1);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m}min';
    } catch (_) {
      return '';
    }
  }

  bool get isCurrentlyPlaying {
    final now = DateTime.now();
    const days = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    final todayName = days[now.weekday - 1];
    if (day != todayName) return false;
    try {
      final startParts = startTime.split(':').map(int.parse).toList();
      final endParts = endTime.split(':').map(int.parse).toList();
      final start = DateTime(now.year, now.month, now.day, startParts[0], startParts[1]);
      DateTime end = DateTime(now.year, now.month, now.day, endParts[0], endParts[1]);
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }
}
