import 'package:opration/features/wallets/data/datasources/wallet_local_data_source.dart';
import 'package:opration/features/wallets/data/models/transfer_record_model.dart';
import 'package:opration/features/wallets/data/models/wallet_model.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/domain/repositories/wallet_repository.dart';
import 'package:uuid/uuid.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required this.localDataSource,
    required this.uuid,
  });

  final WalletLocalDataSource localDataSource;
  final Uuid uuid;

  @override
  Future<List<Wallet>> getWallets() async {
    final walletModels = await localDataSource.getWallets();
    return List<Wallet>.from(walletModels);
  }

  @override
  Future<Wallet> getWalletById(String id) async {
    final currentWallets = await localDataSource.getWallets();
    final wallet = currentWallets.firstWhere(
      (w) => w.id == id,
      orElse: () => throw Exception('المحفظة غير موجودة'),
    );
    return wallet;
  }

  @override
  Future<void> addWallet(Wallet wallet) async {
    final currentWallets = await localDataSource.getWallets();
    final updatedWallets = List<WalletModel>.from(currentWallets)
      ..add(WalletModel.fromEntity(wallet));
    await localDataSource.saveWallets(updatedWallets);
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    final currentWallets = await localDataSource.getWallets();
    final index = currentWallets.indexWhere((w) => w.id == wallet.id);

    if (index != -1) {
      final updatedWallets = List<WalletModel>.from(currentWallets);
      updatedWallets[index] = WalletModel.fromEntity(wallet);
      await localDataSource.saveWallets(updatedWallets);
    } else {
      throw Exception('لا يمكن تحديث محفظة غير موجودة');
    }
  }

  @override
  Future<void> updateBalance(String walletId, double amountChange) async {
    final currentWallets = await localDataSource.getWallets();
    final index = currentWallets.indexWhere((w) => w.id == walletId);

    if (index != -1) {
      final oldWallet = currentWallets[index];
      final newBalance = oldWallet.balance + amountChange;
      final updatedWallet = oldWallet.copyWith(balance: newBalance);

      final updatedWallets = List<WalletModel>.from(currentWallets);
      updatedWallets[index] = WalletModel.fromEntity(updatedWallet);
      await localDataSource.saveWallets(updatedWallets);
    } else {
      throw Exception('لم يتم العثور على المحفظة لتحديث رصيدها');
    }
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    final currentWallets = await localDataSource.getWallets();
    final walletIndex = currentWallets.indexWhere((w) => w.id == walletId);
    if (walletIndex == -1) return;

    final walletToRemove = currentWallets[walletIndex];

    if (walletToRemove.type == WalletType.savings) {
      throw Exception('لا يمكن حذف محفظة التوفير الأساسية');
    }

    final updatedWallets = currentWallets
        .where((w) => w.id != walletId)
        .toList();
    await localDataSource.saveWallets(updatedWallets);
  }

  @override
  Future<void> transferBalance(
    String fromWalletId,
    String toWalletId,
    double amount,
  ) async {
    final currentModels = await localDataSource.getWallets();
    final wallets = List<WalletModel>.from(currentModels);

    final fromIndex = wallets.indexWhere((w) => w.id == fromWalletId);
    final toIndex = wallets.indexWhere((w) => w.id == toWalletId);

    if (fromIndex != -1 && toIndex != -1) {
      final fromWallet = wallets[fromIndex];
      final toWallet = wallets[toIndex];

      if (fromWallet.balance < amount) {
        throw Exception('الرصيد غير كافٍ في محفظة ${fromWallet.name}');
      }

      wallets[fromIndex] = WalletModel.fromEntity(
        fromWallet.copyWith(balance: fromWallet.balance - amount),
      );

      wallets[toIndex] = WalletModel.fromEntity(
        toWallet.copyWith(balance: toWallet.balance + amount),
      );

      await localDataSource.saveWallets(wallets);

      await localDataSource.saveTransferRecord(
        TransferRecordModel(
          id: uuid.v4(),
          fromWalletName: fromWallet.name,
          toWalletName: toWallet.name,
          amount: amount,
          date: DateTime.now(),
        ),
      );
    } else {
      throw Exception('إحدى المحافظ المحددة للتحويل غير موجودة');
    }
  }
}
