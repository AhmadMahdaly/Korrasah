import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer, reallocation }

enum BudgetBucketType { allocation, jar, incomeSource, general }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    this.walletId,
    this.allocationId,
    this.categoryId,
    this.incomeSourceId,
    this.budgetBucketId,
    this.budgetBucketType,
    this.fromWalletId,
    this.toWalletId,
    this.fromAllocationId,
    this.toAllocationId,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),

      fromWalletId: json['fromWalletId'] as String?,
      toWalletId: json['toWalletId'] as String?,
      allocationId: json['allocationId'] as String?,
      categoryId: json['categoryId'] as String?,
      fromAllocationId: json['fromAllocationId'] as String?,
      toAllocationId: json['toAllocationId'] as String?,

      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      type: TransactionType.values.byName(json['type'] as String),

      walletId: json['walletId'] as String? ?? 'default_wallet',
      incomeSourceId: json['incomeSourceId'] as String?,
      budgetBucketId: json['budgetBucketId'] as String?,
      budgetBucketType: json['budgetBucketType'] != null
          ? BudgetBucketType.values.byName(json['budgetBucketType'] as String)
          : null,
    );
  }

  final String id;
  final double amount;
  final DateTime date;
  final String? note;
  final TransactionType type;

  final String? walletId;
  final String? fromWalletId;
  final String? toWalletId;

  final String? allocationId;
  final String? categoryId;
  final String? incomeSourceId;
  final String? budgetBucketId;
  final BudgetBucketType? budgetBucketType;
  final String? fromAllocationId;
  final String? toAllocationId;

  String? get primaryCategoryId =>
      categoryId ?? allocationId ?? budgetBucketId ?? incomeSourceId;

  @override
  List<Object?> get props => [
    id,
    amount,
    fromWalletId,
    toWalletId,
    allocationId,
    categoryId,
    incomeSourceId,
    budgetBucketId,
    budgetBucketType,
    fromAllocationId,
    toAllocationId,
    date,
    note,
    type,
    walletId,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'allocationId': allocationId,
      'categoryId': categoryId,
      'fromAllocationId': fromAllocationId,
      'toAllocationId': toAllocationId,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
      'walletId': walletId,
      'incomeSourceId': incomeSourceId,
      'budgetBucketId': budgetBucketId,
      'budgetBucketType': budgetBucketType?.name,
    };
  }
}
