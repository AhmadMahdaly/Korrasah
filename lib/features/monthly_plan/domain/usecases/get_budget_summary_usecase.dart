// ignore_for_file: omit_local_variable_types

import 'package:opration/features/Allocation/domain/repo/allocation_repo.dart';
import 'package:opration/features/monthly_plan/domain/entities/budget_summary.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';

class GetBudgetSummaryUseCase {
  GetBudgetSummaryUseCase(this.transactionRepo, this.allocationRepo);

  final TransactionRepository transactionRepo;
  final AllocationRepository allocationRepo;

  Future<BudgetSummary> execute(DateTime month) async {
    final String yearMonth =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final allTransactions = await transactionRepo.getTransactions();

    // ✅ فلترة الشهر (سنة + شهر)
    final transactions = allTransactions.where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList();

    final allocations = await allocationRepo.getAllocations(yearMonth);

    double income = 0;
    double expense = 0;

    final double budgeted = allocations.fold(
      0,
      (sum, item) => sum + item.budgetedAmount,
    );

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
