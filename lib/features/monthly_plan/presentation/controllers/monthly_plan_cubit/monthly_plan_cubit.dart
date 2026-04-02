import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/features/monthly_plan/domain/entities/budget_summary.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/domain/usecases/get_budget_summary_usecase.dart';
import 'package:opration/features/monthly_plan/domain/usecases/get_monthly_plan.dart';
import 'package:opration/features/monthly_plan/domain/usecases/save_monthly_plan.dart';

part 'monthly_plan_state.dart';

class MonthlyPlanCubit extends Cubit<MonthlyPlanState> {
  MonthlyPlanCubit({
    required this.getMonthlyPlanUseCase,
    required this.saveMonthlyPlanUseCase,
    required this.getBudgetSummaryUseCase,
  }) : super(MonthlyPlanState.initial());

  final GetMonthlyPlanUseCase getMonthlyPlanUseCase;
  final SaveMonthlyPlanUseCase saveMonthlyPlanUseCase;
  final GetBudgetSummaryUseCase getBudgetSummaryUseCase;

  Future<void> loadPlanForMonth(DateTime month) async {
    emit(state.copyWith(status: MonthlyPlanStatus.loading));
    try {
      final yearMonth =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      var plan = await getMonthlyPlanUseCase(yearMonth);

      if (!plan.isStarted && plan.expenses.isEmpty && plan.debts.isEmpty) {
        final prevMonthDate = DateTime(month.year, month.month - 1, 1);
        final prevYearMonth =
            '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';

        final prevPlan = await getMonthlyPlanUseCase(prevYearMonth);

        if (prevPlan.expenses.isNotEmpty ||
            prevPlan.debts.isNotEmpty ||
            prevPlan.incomes.length > 1) {
          plan = prevPlan.copyWith(
            id: yearMonth,
            isStarted: false,
          );

          await saveMonthlyPlanUseCase(plan);
        }
      }

      final summary = await getBudgetSummaryUseCase.execute(month);

      emit(
        state.copyWith(
          status: MonthlyPlanStatus.loaded,
          plan: plan,
          summary: summary,
          currentMonth: month,
        ),
      );
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: MonthlyPlanStatus.error,
            error: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> saveCurrentPlan() async {
    if (isClosed ||
        state.plan == null ||
        state.status == MonthlyPlanStatus.saving) {
      return;
    }

    emit(state.copyWith(status: MonthlyPlanStatus.saving));

    try {
      await saveMonthlyPlanUseCase(state.plan!);

      final summary = await getBudgetSummaryUseCase.execute(state.currentMonth);

      if (!isClosed) {
        emit(
          state.copyWith(status: MonthlyPlanStatus.loaded, summary: summary),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(status: MonthlyPlanStatus.error, error: e.toString()),
        );
      }
    }
  }

  Future<void> updatePlan(MonthlyPlan plan) async {
    if (isClosed) return;

    emit(state.copyWith(plan: plan));

    try {
      await saveMonthlyPlanUseCase(plan);

      final summary = await getBudgetSummaryUseCase.execute(state.currentMonth);
      if (!isClosed) {
        emit(state.copyWith(summary: summary));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(error: 'فشل الحفظ التلقائي: $e'));
      }
    }
  }

  Future<void> refreshBudgetSummary() async {
    if (isClosed) return;
    try {
      final summary = await getBudgetSummaryUseCase.execute(state.currentMonth);
      emit(state.copyWith(summary: summary));
    } catch (_) {}
  }
}
