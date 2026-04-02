class BudgetSummary {
  BudgetSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBudgeted,
  });
  final double totalIncome;
  final double totalExpense;
  final double totalBudgeted;

  double get netRemaining => totalIncome - totalExpense;

  double get unallocated {
    final value = totalIncome - totalBudgeted;
    return value > 0 ? value : 0.0;
  }
}
