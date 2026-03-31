import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum PlanExecutionType { manual, auto, confirm }

enum EndOfMonthAction { keepRemaining, transferToSavings }

extension PlanExecutionTypeExt on PlanExecutionType {
  String get label {
    switch (this) {
      case PlanExecutionType.manual:
        return 'يدوي';
      case PlanExecutionType.auto:
        return 'تلقائي';
      case PlanExecutionType.confirm:
        return 'يحتاج تأكيد';
    }
  }
}

extension EndOfMonthActionExt on EndOfMonthAction {
  String get label {
    switch (this) {
      case EndOfMonthAction.transferToSavings:
        return 'التحويل للتوفير';
      case EndOfMonthAction.keepRemaining:
        return 'الاحتفاظ بالمتبقي';
    }
  }
}

@immutable
class PlannedIncome extends Equatable {
  const PlannedIncome({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.executionDay = 1,
    this.executionType = PlanExecutionType.manual,
    this.isFixed = true,
    this.targetWalletId,
    this.walletId,
  });

  factory PlannedIncome.fromJson(Map<String, dynamic> map) {
    return PlannedIncome(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'].toString())
          : DateTime.now(),
      executionDay: map['executionDay'] as int? ?? 1,
      executionType: PlanExecutionType.values.firstWhere(
        (e) => e.name == map['executionType'],
        orElse: () => PlanExecutionType.manual,
      ),
      isFixed: map['isFixed'] as bool? ?? true,
      targetWalletId: map['targetWalletId'] as String?,
      walletId: map['walletId'] as String?,
    );
  }

  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final int executionDay;
  final PlanExecutionType executionType;
  final bool isFixed;
  final String? targetWalletId;
  final String? walletId;

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    date,
    executionDay,
    executionType,
    isFixed,
    targetWalletId,
    walletId,
  ];

  PlannedIncome copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    int? executionDay,
    PlanExecutionType? executionType,
    bool? isFixed,
    String? targetWalletId,
    String? walletId,
  }) {
    return PlannedIncome(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      executionDay: executionDay ?? this.executionDay,
      executionType: executionType ?? this.executionType,
      isFixed: isFixed ?? this.isFixed,
      targetWalletId: targetWalletId ?? this.targetWalletId,
      walletId: walletId ?? this.walletId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'date': date.toIso8601String(),
    'executionDay': executionDay,
    'executionType': executionType.name,
    'isFixed': isFixed,
    'targetWalletId': targetWalletId,
    'walletId': walletId,
  };
}

@immutable
class PlannedExpense extends Equatable {
  const PlannedExpense({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.budgetedAmount,
    this.sourceId,
    this.endOfMonthAction = EndOfMonthAction.keepRemaining,
    this.walletId,
  });

  factory PlannedExpense.fromJson(Map<String, dynamic> map) {
    return PlannedExpense(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      budgetedAmount: (map['budgetedAmount'] as num?)?.toDouble() ?? 0.0,
      sourceId: map['sourceId'] as String?,
      endOfMonthAction: EndOfMonthAction.values.firstWhere(
        (e) => e.name == map['endOfMonthAction'],
        orElse: () => EndOfMonthAction.keepRemaining,
      ),
      walletId: map['walletId'] as String?,
    );
  }

  final String id;
  final String name;
  final String categoryId;
  final double budgetedAmount;
  final String? sourceId;
  final EndOfMonthAction endOfMonthAction;
  final String? walletId;

  @override
  List<Object?> get props => [
    id,
    name,
    categoryId,
    budgetedAmount,
    sourceId,
    endOfMonthAction,
    walletId,
  ];

  PlannedExpense copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? budgetedAmount,
    String? sourceId,
    EndOfMonthAction? endOfMonthAction,
    String? walletId,
  }) {
    return PlannedExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      sourceId: sourceId ?? this.sourceId,
      endOfMonthAction: endOfMonthAction ?? this.endOfMonthAction,
      walletId: walletId ?? this.walletId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'budgetedAmount': budgetedAmount,
    'sourceId': sourceId,
    'endOfMonthAction': endOfMonthAction.name,
    'walletId': walletId,
  };
}

@immutable
class PlannedDebt extends Equatable {
  const PlannedDebt({
    required this.id,
    required this.name,
    required this.amount,
    this.executionDay = 1,
    this.executionType = PlanExecutionType.manual,
    this.sourceId,
  });

  factory PlannedDebt.fromJson(Map<String, dynamic> map) {
    return PlannedDebt(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      executionDay: map['executionDay'] as int? ?? 1,
      executionType: PlanExecutionType.values.firstWhere(
        (e) => e.name == map['executionType'],
        orElse: () => PlanExecutionType.manual,
      ),
      sourceId: map['sourceId'] as String?,
    );
  }
  final String id;
  final String name;
  final double amount;
  final int executionDay;
  final PlanExecutionType executionType;
  final String? sourceId;

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    executionDay,
    executionType,
    sourceId,
  ];

  PlannedDebt copyWith({
    String? id,
    String? name,
    double? amount,
    int? executionDay,
    PlanExecutionType? executionType,
    String? sourceId,
  }) {
    return PlannedDebt(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      executionDay: executionDay ?? this.executionDay,
      executionType: executionType ?? this.executionType,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'executionDay': executionDay,
    'executionType': executionType.name,
    'sourceId': sourceId,
  };
}

@immutable
class MonthlyPlan extends Equatable {
  const MonthlyPlan({
    required this.id,
    this.incomes = const [],
    this.expenses = const [],
    this.debts = const [],
    this.isStarted = false,
  });

  factory MonthlyPlan.fromJson(Map<String, dynamic> map) {
    return MonthlyPlan(
      id: map['id'] as String? ?? '',
      incomes: List<PlannedIncome>.from(
        (map['incomes'] as List?)?.map(
              (x) => PlannedIncome.fromJson(x as Map<String, dynamic>),
            ) ??
            [],
      ),
      expenses: List<PlannedExpense>.from(
        (map['expenses'] as List?)?.map(
              (x) => PlannedExpense.fromJson(x as Map<String, dynamic>),
            ) ??
            [],
      ),
      debts: List<PlannedDebt>.from(
        (map['debts'] as List?)?.map(
              (x) => PlannedDebt.fromJson(x as Map<String, dynamic>),
            ) ??
            [],
      ),
      isStarted: map['isStarted'] as bool? ?? false,
    );
  }

  final String id;
  final List<PlannedIncome> incomes;
  final List<PlannedExpense> expenses;
  final List<PlannedDebt> debts;
  final bool isStarted;

  double get totalPlannedIncome =>
      incomes.fold(0, (sum, item) => sum + item.amount);
  double get totalBudgetedExpense => expenses
      .where((e) => e.walletId == null)
      .fold(0, (sum, item) => sum + item.budgetedAmount);
  double get totalPlannedDebts =>
      debts.fold(0, (sum, item) => sum + item.amount);

  @override
  List<Object> get props => [id, incomes, expenses, debts, isStarted];

  MonthlyPlan copyWith({
    String? id,
    List<PlannedIncome>? incomes,
    List<PlannedExpense>? expenses,
    List<PlannedDebt>? debts,
    bool? isStarted,
  }) {
    return MonthlyPlan(
      id: id ?? this.id,
      incomes: incomes ?? this.incomes,
      expenses: expenses ?? this.expenses,
      debts: debts ?? this.debts,
      isStarted: isStarted ?? this.isStarted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'incomes': incomes.map((x) => x.toJson()).toList(),
    'expenses': expenses.map((x) => x.toJson()).toList(),
    'debts': debts.map((x) => x.toJson()).toList(),
    'isStarted': isStarted,
  };

  PlannedExpense? getExpenseForCategory(String categoryId) {
    try {
      return expenses.firstWhere((e) => e.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }
}
