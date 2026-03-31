import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/domain/usecases/get_monthly_plan.dart';
import 'package:opration/features/monthly_plan/domain/usecases/save_monthly_plan.dart';

part 'monthly_plan_state.dart';

class MonthlyPlanCubit extends Cubit<MonthlyPlanState> {
  MonthlyPlanCubit({
    required this.getMonthlyPlanUseCase,
    required this.saveMonthlyPlanUseCase,
  }) : super(MonthlyPlanState.initial());
  final GetMonthlyPlanUseCase getMonthlyPlanUseCase;
  final SaveMonthlyPlanUseCase saveMonthlyPlanUseCase;

  // String _getYearMonth(DateTime date) {
  //   return DateFormat('yyyy-MM').format(date);
  // }

  Future<void> saveCurrentPlan() async {
    if (isClosed ||
        state.plan == null ||
        state.status == MonthlyPlanStatus.saving) {
      return;
    }
    emit(state.copyWith(status: MonthlyPlanStatus.saving));
    try {
      await saveMonthlyPlanUseCase(state.plan!);

      if (!isClosed) {
        emit(state.copyWith(status: MonthlyPlanStatus.loaded));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(status: MonthlyPlanStatus.error, error: e.toString()),
        );
      }
    }
  }

  // Future<void> loadPlanForMonth(DateTime month) async {
  //   if (state.plan != null) {
  //     await saveCurrentPlan();
  //   }

  //   if (isClosed) return;

  //   emit(state.copyWith(status: MonthlyPlanStatus.loading));
  //   try {
  //     final yearMonth = _getYearMonth(month);
  //     final plan = await getMonthlyPlanUseCase(yearMonth);
  //     if (!isClosed) {
  //       emit(
  //         state.copyWith(
  //           status: MonthlyPlanStatus.loaded,
  //           plan: plan,
  //           currentMonth: month,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (!isClosed) {
  //       emit(
  //         state.copyWith(status: MonthlyPlanStatus.error, error: e.toString()),
  //       );
  //     }
  //   }
  // }

  Future<void> loadPlanForMonth(DateTime month) async {
    emit(state.copyWith(status: MonthlyPlanStatus.loading));
    try {
      final yearMonth =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      var plan = await getMonthlyPlanUseCase(yearMonth);

      // =====================================
      // --- لوجيك الترحيل الذكي للشهر الجديد ---
      // =====================================
      // لو الخطة الحالية "جديدة تماماً" (مفيش مخصصات ولا ديون ولسة مابدأتش)
      if (!plan.isStarted && plan.expenses.isEmpty && plan.debts.isEmpty) {
        final prevMonthDate = DateTime(month.year, month.month - 1, 1);
        final prevYearMonth =
            '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';

        final prevPlan = await getMonthlyPlanUseCase(prevYearMonth);

        // لو الشهر اللي فات كان فيه خطة فعلية (فيها مخصصات أو ديون أو مصادر دخل إضافية)
        if (prevPlan.expenses.isNotEmpty ||
            prevPlan.debts.isNotEmpty ||
            prevPlan.incomes.length > 1) {
          plan = prevPlan.copyWith(
            id: yearMonth,
            isStarted:
                false, // الأهم: إجبار الخطة إنها تكون (مسودة) تحتاج تأكيد
            // 💡 ملاحظة: إحنا بنحتفظ بنفس الأرقام (المبالغ) كنوع من التسهيل لتوفير الوقت.
            // إذا كنت تفضل أن يتم "تصفير" كل المبالغ ليبدأ المستخدم التوزيع من صفر،
            // قم بفك التعليق عن السطرين التاليين:

            // expenses: prevPlan.expenses.map((e) => e.copyWith(budgetedAmount: 0.0)).toList(),
            // incomes: prevPlan.incomes.map((i) => i.copyWith(amount: 0.0)).toList(),
          );

          await saveMonthlyPlanUseCase(plan);
        }
      }

      emit(
        state.copyWith(
          status: MonthlyPlanStatus.loaded,
          plan: plan,
          currentMonth: month,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MonthlyPlanStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> updatePlan(MonthlyPlan plan) async {
    if (isClosed) return;

    emit(state.copyWith(plan: plan));

    try {
      await saveMonthlyPlanUseCase(plan);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(error: 'فشل الحفظ التلقائي: $e'));
      }
    }
  }
}
