import 'package:equatable/equatable.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';

enum WalletType { mainBudget, savings, sideIndependent, sideLinked }

enum ExecutionType { auto, confirm, manual, none }

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    this.isMain = false,
    this.type = WalletType.sideIndependent,
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
  final bool isMain;
  final WalletType type;

  final double? monthlyAmount;
  final int? executionDay;
  final ExecutionType executionType;
  final String? sourceWalletId;

  final RecurrenceType recurrenceType;
  final List<int> selectedDays;
  final DateTime? startDate;
  final DateTime? lastProcessedDate;
  final bool includeInTotal;

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isMain,
    WalletType? type,
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
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isMain: isMain ?? this.isMain,
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
    isMain,
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
  ];
}
