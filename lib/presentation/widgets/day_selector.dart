import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final String currentDay;
  final ValueChanged<String> onDayChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.currentDay,
    required this.onDayChanged,
  });

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
          final bool isToday = day == currentDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.substring(0, 3),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onDayChanged(day),
              selectedColor: ThemeConfig.white,
              backgroundColor: ThemeConfig.darkGrey.withOpacity(0.05),
              shape: StadiumBorder(
                side: BorderSide(color: ThemeConfig.primaryOrange),
              ),
              labelStyle: TextStyle(
                color:
                    isSelected ? ThemeConfig.primaryOrange : ThemeConfig.darkGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
