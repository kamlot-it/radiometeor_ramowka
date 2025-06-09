import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final ValueChanged<String> onDayChanged;

  const DaySelector({super.key, required this.selectedDay, required this.onDayChanged});

  static const List<String> days = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final bool isSelected = day == selectedDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                day.substring(0, 3),
                overflow: TextOverflow.ellipsis,
              ),
              selected: isSelected,
              onSelected: (_) => onDayChanged(day),
              selectedColor: ThemeConfig.primaryOrange,
              backgroundColor: ThemeConfig.darkGrey.withOpacity(0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : ThemeConfig.darkGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
