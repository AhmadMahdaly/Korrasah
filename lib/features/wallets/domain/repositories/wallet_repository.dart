import 'package:opration/features/wallets/domain/entities/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getWallets();
  Future<Wallet> getWalletById(String id);
  Future<void> addWallet(Wallet wallet);
  Future<void> updateWallet(Wallet wallet);
  Future<void> deleteWallet(String walletId);

  Future<void> updateBalance(String walletId, double amountChange);

  Future<void> transferBalance(
    String fromWalletId,
    String toWalletId,
    double amount,
  );
}
