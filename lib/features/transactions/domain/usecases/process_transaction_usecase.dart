import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:opration/features/wallets/domain/repositories/wallet_repository.dart';

class ProcessTransactionUseCase {
  ProcessTransactionUseCase({
    required this.transactionRepo,
    required this.walletRepo,
  });

  final TransactionRepository transactionRepo;
  final WalletRepository walletRepo;

  Future<void> execute(Transaction transaction, {bool isRevert = false}) async {
    final multiplier = isRevert ? -1.0 : 1.0;
    final effectiveAmount = transaction.amount * multiplier;

    switch (transaction.type) {
      case TransactionType.expense:
        await walletRepo.updateBalance(transaction.walletId!, -effectiveAmount);

      case TransactionType.income:
        await walletRepo.updateBalance(transaction.walletId!, effectiveAmount);

      case TransactionType.transfer:
        await walletRepo.updateBalance(
          transaction.fromWalletId!,
          -effectiveAmount,
        );
        await walletRepo.updateBalance(
          transaction.toWalletId!,
          effectiveAmount,
        );

      case TransactionType.reallocation:
        break;
    }

    if (isRevert) {
      await transactionRepo.deleteTransaction(transaction.id);
    } else {
      await transactionRepo.addTransaction(transaction);
    }
  }
}
