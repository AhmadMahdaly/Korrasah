import 'dart:convert';

import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/features/wallets/data/models/transfer_record_model.dart';
import 'package:opration/features/wallets/data/models/wallet_model.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class WalletLocalDataSource {
  Future<List<WalletModel>> getWallets();
  Future<void> saveWallets(List<WalletModel> wallets);
  Future<bool> getShowMainWalletPref();
  Future<void> setShowMainWalletPref(bool show);
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
      final wallets = jsonList
          .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return wallets;
    } else {
      const mainWallet = WalletModel(
        id: 'main_budget_id',
        name: 'محفظة الميزانية',
        balance: 0,
        isMain: true,
        type: WalletType.mainBudget,
      );
      const savingsWallet = WalletModel(
        id: 'savings_wallet_id',
        name: 'محفظة التوفير',
        balance: 0,
        isMain: false,
        type: WalletType.savings,
      );

      await saveWallets([mainWallet, savingsWallet]);
      return [mainWallet, savingsWallet];
    }
  }

  @override
  Future<void> saveWallets(List<WalletModel> wallets) {
    final jsonList = wallets.map((wallet) => wallet.toJson()).toList();
    return sharedPreferences.setString(
      CacheKeys.cachedWallets,
      json.encode(jsonList),
    );
  }

  @override
  Future<bool> getShowMainWalletPref() {
    return Future.value(
      sharedPreferences.getBool(CacheKeys.showMainWalletPref) ?? true,
    );
  }

  @override
  Future<void> setShowMainWalletPref(bool show) {
    return sharedPreferences.setBool(CacheKeys.showMainWalletPref, show);
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
    if (jsonString == null) return [];
    final jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((j) => TransferRecordModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
