import 'package:equatable/equatable.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';

enum WalletType { savings, real, jar }

enum ExecutionType { auto, confirm, manual, none }

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    this.iconName,
    this.colorValue,
    this.type = WalletType.real,
    this.monthlyAmount,
    this.executionDay,
    this.executionType = ExecutionType.none,
    this.sourceWalletId,
    this.recurrenceType = RecurrenceType.none,
    this.selectedDays = const [],
    this.startDate,
    this.lastProcessedDate,
    this.includeInTotal = true,
  });

  final String id;
  final String name;
  final double balance;
  final String? iconName;
  final WalletType type;
  final int? colorValue;
  final double? monthlyAmount;
  final int? executionDay;
  final ExecutionType executionType;
  final String? sourceWalletId;

  final RecurrenceType recurrenceType;
  final List<int> selectedDays;
  final DateTime? startDate;
  final DateTime? lastProcessedDate;
  final bool includeInTotal;

  bool get isSavingsWallet => type == WalletType.savings;

  bool get isHasala => type == WalletType.jar;

  bool get isRealWallet => type == WalletType.real;

  bool get isBudgetBucket => isSavingsWallet || isHasala;

  double get plannedMonthlyFunding => monthlyAmount ?? 0.0;

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? iconName,
    WalletType? type,
    int? colorValue,
    double? monthlyAmount,
    int? executionDay,
    ExecutionType? executionType,
    String? sourceWalletId,
    RecurrenceType? recurrenceType,
    List<int>? selectedDays,
    DateTime? startDate,
    DateTime? lastProcessedDate,
    bool? includeInTotal,
  }) {
    return Wallet(
      id: id ?? this.id,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      executionDay: executionDay ?? this.executionDay,
      executionType: executionType ?? this.executionType,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      selectedDays: selectedDays ?? this.selectedDays,
      startDate: startDate ?? this.startDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      includeInTotal: includeInTotal ?? this.includeInTotal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    balance,
    iconName,
    type,
    monthlyAmount,
    executionDay,
    executionType,
    sourceWalletId,
    recurrenceType,
    selectedDays,
    startDate,
    lastProcessedDate,
    includeInTotal,
    colorValue,
  ];
}
