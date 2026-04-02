import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.type,
    required super.colorValue,
    super.monthlyAmount,
    super.executionDay,
    super.executionType,
    super.sourceWalletId,
    super.recurrenceType = RecurrenceType.none,
    super.selectedDays = const [],
  });

  factory WalletModel.fromEntity(Wallet wallet) {
    return WalletModel(
      id: wallet.id,
      name: wallet.name,
      balance: wallet.balance,
      type: wallet.type,
      monthlyAmount: wallet.monthlyAmount,
      executionDay: wallet.executionDay,
      executionType: wallet.executionType,
      sourceWalletId: wallet.sourceWalletId,
      recurrenceType: wallet.recurrenceType,
      selectedDays: wallet.selectedDays,
      colorValue: wallet.colorValue,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      balance: (json['balance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,

      type: WalletType.values.firstWhere(
        (e) => e.toString() == json['type'] || e.name == json['type'],
        orElse: () => WalletType.sideIndependent,
      ),

      monthlyAmount: json['monthlyAmount'] != null
          ? (json['monthlyAmount'] as num).toDouble()
          : null,
      executionDay: json['executionDay'] as int?,
      executionType: ExecutionType.values.firstWhere(
        (e) => e.toString() == json['executionType'],
        orElse: () => ExecutionType.none,
      ),
      sourceWalletId: json['sourceWalletId']?.toString(),

      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      selectedDays: (json['selectedDays'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.name,
      'monthlyAmount': monthlyAmount,
      'executionDay': executionDay,
      'executionType': executionType.toString(),
      'sourceWalletId': sourceWalletId,
      'recurrenceType': recurrenceType.name,
      'selectedDays': selectedDays,
      'colorValue': colorValue,
    };
  }
}
