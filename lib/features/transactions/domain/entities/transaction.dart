import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer, reallocation }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    this.walletId,
    this.allocationId,
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
      fromAllocationId: json['fromAllocationId'] as String?,
      toAllocationId: json['toAllocationId'] as String?,

      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      type: TransactionType.values.byName(json['type'] as String),

      walletId: json['walletId'] as String? ?? 'default_wallet',
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
  final String? fromAllocationId;
  final String? toAllocationId;

  @override
  List<Object?> get props => [
    id,
    amount,
    fromWalletId,
    toWalletId,
    allocationId,
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
      'fromAllocationId': fromAllocationId,
      'toAllocationId': toAllocationId,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
      'walletId': walletId,
    };
  }
}
