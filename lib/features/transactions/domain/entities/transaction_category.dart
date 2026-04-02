import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';

enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekends,
  weekly,
  biWeekly,
  everyFourWeeks,
  monthly,
  endOfMonth,
  everyTwoMonths,
  everyThreeMonths,
  everyFourMonths,
  everySixMonths,
  yearly,
}

// إضافة Equatable لضمان تحديث الـ State عند التعديل
class RecurringPlan extends Equatable {
  const RecurringPlan({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.startDate,
    required this.targetWalletId,
    this.selectedDays = const [],
    this.lastProcessedDate,
  });

  final String id;
  final String title;
  final double amount;
  final RecurrenceType type;
  final List<int> selectedDays;
  final DateTime startDate;
  final DateTime? lastProcessedDate;
  final String targetWalletId;

  RecurringPlan copyWithLastProcessed(DateTime newDate) {
    return RecurringPlan(
      id: id,
      title: title,
      amount: amount,
      type: type,
      selectedDays: selectedDays,
      startDate: startDate,
      lastProcessedDate: newDate,
      targetWalletId: targetWalletId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    selectedDays,
    startDate,
    lastProcessedDate,
    targetWalletId,
  ];
}

// إضافة Equatable لضمان شعور الـ Cubit بأي تعديل في الفئة
class TransactionCategory extends Equatable {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.type,
    this.isRecurring = false,
    this.fixedAmount,
    this.recurrenceType = RecurrenceType.none,
    this.dayOfMonth,
    this.daysOfWeek,
    this.autoDeduct = false,
    this.targetWalletId,
    this.parentId,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      TransactionCategory(
        id: json['id'].toString(),
        name: json['name'].toString(),
        colorValue: json['colorValue'] as int,
        // قراءة آمنة تدعم الـ Name الجديد والـ toString القديم
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'] || e.toString() == json['type'],
          orElse: () => TransactionType.expense,
        ),
        isRecurring: json['isRecurring'] as bool? ?? false,
        fixedAmount: (json['fixedAmount'] as num?)?.toDouble(),
        recurrenceType: RecurrenceType.values.firstWhere(
          (e) => e.name == (json['recurrenceType'] ?? 'none'),
          orElse: () => RecurrenceType.none,
        ),
        parentId: json['parentId']?.toString(),
        targetWalletId: json['targetWalletId']?.toString(),
        dayOfMonth: json['dayOfMonth'] as int?,
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.cast<int>(),
        autoDeduct: json['autoDeduct'] as bool? ?? false,
      );

  final String id;
  final String name;
  final int colorValue;
  final TransactionType type;
  final String? parentId;
  final String? targetWalletId;
  final bool isRecurring;
  final double? fixedAmount;
  final RecurrenceType recurrenceType;
  final int? dayOfMonth;
  final List<int>? daysOfWeek;
  final bool autoDeduct;

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'type': type.name, // استخدام .name بدلاً من .toString() للوضوح والتوحيد
    'isRecurring': isRecurring,
    'fixedAmount': fixedAmount,
    'recurrenceType': recurrenceType.name,
    'dayOfMonth': dayOfMonth,
    'daysOfWeek': daysOfWeek,
    'autoDeduct': autoDeduct,
    'parentId': parentId,
    'targetWalletId': targetWalletId,
  };

  TransactionCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    TransactionType? type,
    bool? isRecurring,
    double? fixedAmount,
    RecurrenceType? recurrenceType,
    int? dayOfMonth,
    List<int>? daysOfWeek,
    bool? autoDeduct,
    String? targetWalletId,
    String? parentId,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      autoDeduct: autoDeduct ?? this.autoDeduct,
      targetWalletId: targetWalletId ?? this.targetWalletId,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    colorValue,
    type,
    isRecurring,
    fixedAmount,
    recurrenceType,
    dayOfMonth,
    daysOfWeek,
    autoDeduct,
    targetWalletId,
    parentId,
  ];
}
