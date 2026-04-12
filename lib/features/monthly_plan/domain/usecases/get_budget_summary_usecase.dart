// ignore_for_file: omit_local_variable_types

import 'package:opration/features/monthly_plan/domain/entities/budget_summary.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:opration/features/wallets/domain/repositories/wallet_repository.dart';

class GetBudgetSummaryUseCase {
  GetBudgetSummaryUseCase(this.transactionRepo, this.walletRepository);

  final TransactionRepository transactionRepo;
  final WalletRepository walletRepository;

  Future<BudgetSummary> execute(DateTime month) async {
    final String yearMonth =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final allTransactions = await transactionRepo.getTransactions();

    // ✅ فلترة الشهر (سنة + شهر)
    final transactions = allTransactions.where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList();

    final plan = await transactionRepo.getMonthlyPlan(yearMonth);
    final wallets = await walletRepository.getWallets();

    double income = 0;
    double expense = 0;

    final hasalatPlanned = wallets
        .where((wallet) => wallet.isHasala)
        .fold<double>(0, (sum, wallet) => sum + wallet.plannedMonthlyFunding);

    final savingsTarget = wallets
        .where((wallet) => wallet.isSavingsWallet)
        .fold<double>(0, (sum, wallet) => sum + wallet.plannedMonthlyFunding);

    final double budgeted =
        plan.totalBudgetedExpense +
        plan.totalPlannedDebts +
        hasalatPlanned +
        savingsTarget;

    for (final tx in transactions) {
      // 🔴 استبعاد التحويلات
      if (tx.type == TransactionType.transfer) continue;

      // 🔴 استبعاد الرصيد الافتتاحي
      if (tx.note == 'رصيد افتتاح المحفظة') continue;

      // ✅ الحساب الحقيقي فقط
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    return BudgetSummary(
      totalIncome: income,
      totalExpense: expense,
      totalBudgeted: budgeted,
    );
  }
}
