import 'package:flutter/material.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';

class RecurrenceSelector extends StatelessWidget {
  const RecurrenceSelector({
    required this.onChanged,
    required this.value,
    required this.selectedDays,
    super.key,
  });

  final RecurrenceType value;
  final List<int> selectedDays;
  final void Function(RecurrenceType, List<int>) onChanged;

  static const Map<RecurrenceType, String> _recurrenceNames = {
    RecurrenceType.none: 'لا شيء (مرة واحدة)',
    RecurrenceType.daily: 'كل يوم',
    RecurrenceType.weekdays: 'أيام العمل (الأحد - الخميس)',
    RecurrenceType.weekends: 'الويك إند (الجمعة - السبت)',
    RecurrenceType.weekly: 'كل أسبوع',
    RecurrenceType.biWeekly: 'كل أسبوعين',
    RecurrenceType.everyFourWeeks: 'كل 4 أسابيع',
    RecurrenceType.monthly: 'كل شهر',
    RecurrenceType.endOfMonth: 'آخر الشهر',
    RecurrenceType.everyTwoMonths: 'كل شهرين',
    RecurrenceType.everyThreeMonths: 'كل 3 أشهر',
    RecurrenceType.everyFourMonths: 'كل 4 أشهر',
    RecurrenceType.everySixMonths: 'كل 6 أشهر',
    RecurrenceType.yearly: 'كل سنة',
  };

  static const List<Map<String, dynamic>> _weekDays = [
    {'name': 'السبت', 'val': 6},
    {'name': 'الأحد', 'val': 7},
    {'name': 'الإثنين', 'val': 1},
    {'name': 'الثلاثاء', 'val': 2},
    {'name': 'الأربعاء', 'val': 3},
    {'name': 'الخميس', 'val': 4},
    {'name': 'الجمعة', 'val': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'تكرار العملية',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                10,
              ),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: RecurrenceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_recurrenceNames[type]!),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != value) {
              onChanged(val, []);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildDynamicSelector(context),
      ],
    );
  }

  Widget _buildDynamicSelector(BuildContext context) {
    final needsWeekDays = [
      RecurrenceType.weekly,
      RecurrenceType.biWeekly,
      RecurrenceType.everyFourWeeks,
    ];
    final needsMonthDays = [
      RecurrenceType.monthly,
      RecurrenceType.everyTwoMonths,
      RecurrenceType.everyThreeMonths,
      RecurrenceType.everyFourMonths,
      RecurrenceType.everySixMonths,
    ];
    final needsFullDate = [
      RecurrenceType.yearly,
    ];

    if (needsWeekDays.contains(value)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر أيام الأسبوع:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final isSelected = selectedDays.contains(day['val']);
              return FilterChip(
                label: Text(day['name'].toString()),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor.withAlpha(40),
                checkmarkColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (selected) {
                  final newDays = List<int>.from(selectedDays);
                  if (selected) {
                    newDays.add(day['val'] as int);
                  } else {
                    newDays.remove(day['val']);
                  }
                  onChanged(value, newDays);
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    if (needsMonthDays.contains(value)) {
      var currentDay = selectedDays.isNotEmpty ? selectedDays.first : null;

      if (currentDay != null && (currentDay < 1 || currentDay > 31)) {
        currentDay = 1;
      }

      return DropdownButtonFormField<int>(
        value: currentDay,
        decoration: InputDecoration(
          labelText: 'يوم التنفيذ في الشهر',
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: List.generate(31, (index) {
          final day = index + 1;
          return DropdownMenuItem(
            value: day,
            child: Text('يوم $day'),
          );
        }),
        onChanged: (val) {
          if (val != null) {
            onChanged(value, [val]);
          }
        },
      );
    }

    if (needsFullDate.contains(value)) {
      var dateText = 'اختر تاريخ التنفيذ السنوي';
      if (selectedDays.length == 2) {
        dateText = 'يوم ${selectedDays[1]} / شهر ${selectedDays[0]}';
      }

      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            helpText: 'اختر تاريخ التكرار السنوي',
          );

          if (picked != null) {
            onChanged(value, [picked.month, picked.day]);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateText,
                style: TextStyle(
                  color: selectedDays.length == 2
                      ? Colors.black87
                      : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
