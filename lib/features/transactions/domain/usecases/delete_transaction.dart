import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:opration/features/transactions/domain/usecases/process_transaction_usecase.dart';

class DeleteTransactionUseCase {
  DeleteTransactionUseCase(this.processTransaction, this.transactionRepo);
  final ProcessTransactionUseCase processTransaction;
  final TransactionRepository transactionRepo;

  Future<void> execute(String transactionId) async {
    final oldTx = await transactionRepo.getTransactionById(transactionId);

    await processTransaction.execute(oldTx, isRevert: true);
  }
}
