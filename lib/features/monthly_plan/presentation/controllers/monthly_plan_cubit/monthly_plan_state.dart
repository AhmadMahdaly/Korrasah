part of 'monthly_plan_cubit.dart';

enum MonthlyPlanStatus { initial, loading, saving, loaded, error }

class MonthlyPlanState extends Equatable {
  const MonthlyPlanState({
    required this.status,
    required this.currentMonth,
    this.plan,
    this.summary,
    this.error,
  });

  factory MonthlyPlanState.initial() {
    return MonthlyPlanState(
      status: MonthlyPlanStatus.initial,
      currentMonth: DateTime.now(),
    );
  }

  final MonthlyPlanStatus status;
  final DateTime currentMonth;
  final MonthlyPlan? plan;
  final BudgetSummary? summary;
  final String? error;

  MonthlyPlanState copyWith({
    MonthlyPlanStatus? status,
    DateTime? currentMonth,
    MonthlyPlan? plan,
    BudgetSummary? summary,
    String? error,
  }) {
    return MonthlyPlanState(
      status: status ?? this.status,
      currentMonth: currentMonth ?? this.currentMonth,
      plan: plan ?? this.plan,
      summary: summary ?? this.summary,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, currentMonth, plan, summary, error];
}
