import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:opration/features/transactions/domain/usecases/process_transaction_usecase.dart';

class UpdateTransactionUseCase {
  UpdateTransactionUseCase(this.processTransaction, this.transactionRepo);
  final ProcessTransactionUseCase processTransaction;
  final TransactionRepository transactionRepo;

  Future<void> execute(Transaction newTx) async {
    final oldTx = await transactionRepo.getTransactionById(newTx.id);

    await processTransaction.execute(oldTx, isRevert: true);

    await processTransaction.execute(newTx, isRevert: false);
  }
}
