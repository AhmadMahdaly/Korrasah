import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/features/wallets/data/models/transfer_record_model.dart';
import 'package:opration/features/wallets/data/models/wallet_model.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class WalletLocalDataSource {
  Future<List<WalletModel>> getWallets();
  Future<void> saveWallets(List<WalletModel> wallets);
  Future<void> saveTransferRecord(TransferRecordModel record);
  Future<List<TransferRecordModel>> getTransferHistory();
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.uuid,
  });

  final SharedPreferences sharedPreferences;
  final Uuid uuid;

  @override
  Future<List<WalletModel>> getWallets() async {
    final jsonString = sharedPreferences.getString(CacheKeys.cachedWallets);
    if (jsonString != null && jsonString.isNotEmpty) {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final savingsWallet = WalletModel(
        id: 'savings_wallet_id',
        name: 'التوفير',
        colorValue: Colors.amber.value,
        balance: 0,
        type: WalletType.savings,
      );

      await saveWallets([savingsWallet]);
      return [savingsWallet];
    }
  }

  @override
  Future<void> saveWallets(List<WalletModel> wallets) async {
    final jsonList = wallets.map((wallet) => wallet.toJson()).toList();
    await sharedPreferences.setString(
      CacheKeys.cachedWallets,
      json.encode(jsonList),
    );
  }

  @override
  Future<void> saveTransferRecord(TransferRecordModel record) async {
    final records = await getTransferHistory();
    records.insert(0, record);
    final jsonList = records.map((r) => r.toJson()).toList();
    await sharedPreferences.setString(
      'transfer_history',
      json.encode(jsonList),
    );
  }

  @override
  Future<List<TransferRecordModel>> getTransferHistory() async {
    final jsonString = sharedPreferences.getString('transfer_history');
    if (jsonString == null || jsonString.isEmpty) return [];

    final jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((j) => TransferRecordModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
