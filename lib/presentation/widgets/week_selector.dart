import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class WeekSelector extends StatelessWidget {
  final String selectedWeek;
  final Function(String) onWeekChanged;

  const WeekSelector({
    super.key,
    required this.selectedWeek,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableWeeks = ['Tydzień A', 'Tydzień B'];

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedWeek,
          dropdownColor: ThemeConfig.white,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: availableWeeks.map((week) {
            return DropdownMenuItem<String>(
              value: week,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWeekIcon(week),
                      size: 16,
                      color: week == selectedWeek
                          ? ThemeConfig.primaryOrange
                          : ThemeConfig.mediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      week,
                      style: TextStyle(
                        color: week == selectedWeek
                            ? ThemeConfig.primaryOrange
                            : ThemeConfig.darkGrey,
                        fontWeight: week == selectedWeek
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (week == selectedWeek) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: ThemeConfig.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newWeek) {
            if (newWeek != null && newWeek != selectedWeek) {
              onWeekChanged(newWeek);
            }
          },
        ),
      ),
    );
  }

  IconData _getWeekIcon(String week) {
    switch (week) {
      case 'Tydzień A':
        return Icons.looks_one;
      case 'Tydzień B':
        return Icons.looks_two;
      default:
        return Icons.calendar_today;
    }
  }
}
