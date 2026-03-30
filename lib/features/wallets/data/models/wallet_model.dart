import 'package:opration/features/wallets/domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.isMain,
    required super.type,
    super.monthlyAmount,
    super.executionDay,
    super.executionType,
    super.sourceWalletId,
  });

  factory WalletModel.fromEntity(Wallet wallet) {
    return WalletModel(
      id: wallet.id,
      name: wallet.name,
      balance: wallet.balance,
      isMain: wallet.isMain,
      type: wallet.type,
      monthlyAmount: wallet.monthlyAmount,
      executionDay: wallet.executionDay,
      executionType: wallet.executionType,
      sourceWalletId: wallet.sourceWalletId,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      balance: (json['balance'] as num).toDouble(),
      isMain: json['isMain'] as bool? ?? false,
      type: WalletType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => json['isMain'] == true
            ? WalletType.mainBudget
            : WalletType.sideIndependent,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'isMain': isMain,
      'type': type.toString(),
      'monthlyAmount': monthlyAmount,
      'executionDay': executionDay,
      'executionType': executionType.toString(),
      'sourceWalletId': sourceWalletId,
    };
  }
}
