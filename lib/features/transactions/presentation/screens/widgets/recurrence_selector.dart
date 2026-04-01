import 'package:flutter/material.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';

class RecurrenceSelector extends StatefulWidget {
  const RecurrenceSelector({
    required this.onChanged,
    super.key,
    this.initialType = RecurrenceType.none,
    this.initialDays = const [],
  });
  final RecurrenceType initialType;
  final List<int> initialDays;
  final Function(RecurrenceType, List<int>) onChanged;

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  late RecurrenceType _selectedType;
  late List<int> _selectedDays;

  final Map<RecurrenceType, String> _recurrenceNames = {
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

  final List<Map<String, dynamic>> _weekDays = [
    {'name': 'السبت', 'val': 6},
    {'name': 'الأحد', 'val': 7},
    {'name': 'الإثنين', 'val': 1},
    {'name': 'الثلاثاء', 'val': 2},
    {'name': 'الأربعاء', 'val': 3},
    {'name': 'الخميس', 'val': 4},
    {'name': 'الجمعة', 'val': 5},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedDays = List.from(widget.initialDays);
  }

  void _updateParent() => widget.onChanged(_selectedType, _selectedDays);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          initialValue: _selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'تكرار العملية',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: RecurrenceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_recurrenceNames[type]!),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedType = val;
                _selectedDays.clear();
              });
              _updateParent();
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDynamicSelector(),
      ],
    );
  }

  Widget _buildDynamicSelector() {
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
      RecurrenceType.yearly,
    ];

    if (needsWeekDays.contains(_selectedType)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر أيام الأسبوع:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weekDays.map((day) {
              final isSelected = _selectedDays.contains(day['val']);
              return FilterChip(
                label: Text(day['name'].toString()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedDays.add(day['val'] as int)
                        : _selectedDays.remove(day['val']);
                  });
                  _updateParent();
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    if (needsMonthDays.contains(_selectedType)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر يوم التنفيذ (1-31):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = _selectedDays.contains(day);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(day.toString()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDays.clear();
                        if (selected) _selectedDays.add(day);
                      });
                      _updateParent();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
