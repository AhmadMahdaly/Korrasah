import 'package:equatable/equatable.dart';

enum WalletType { mainBudget, savings, sideIndependent, sideLinked }

enum ExecutionType { auto, confirm, manual, none }

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    this.isMain = false,
    this.type = WalletType.sideIndependent,
    // الحقول الخاصة بالمحافظ المرتبطة بالميزانية
    this.monthlyAmount,
    this.executionDay,
    this.executionType = ExecutionType.none,
    this.sourceWalletId,
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
  ];
}
