// ignore_for_file: inference_failure_on_function_return_type

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';
import 'package:uuid/uuid.dart';

class SetupMonthlyPlanScreen extends StatelessWidget {
  const SetupMonthlyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<MonthlyPlanCubit>();
      if (cubit.state.plan == null &&
          cubit.state.status != MonthlyPlanStatus.loading) {
        cubit.loadPlanForMonth(DateTime.now());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: false,
        height: 16.h,
        title: 'الخطة الشهرية',
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, planState) {
          if (planState.status == MonthlyPlanStatus.loading ||
              planState.plan == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<WalletCubit, WalletState>(
            builder: (context, walletState) {
              final plan = planState.plan!;
              final wallets = (walletState is WalletLoaded)
                  ? walletState.wallets
                  : <Wallet>[];
              final linkedWallets = wallets
                  .where((w) => w.type == WalletType.sideLinked)
                  .toList();

              // الحسابات الذكية للميزانية الصفرية
              final totalIncome = plan.totalPlannedIncome;
              final linkedWalletsTotal = linkedWallets.fold(
                0.0,
                (s, w) => s + (w.monthlyAmount ?? 0),
              );
              final totalAllocated =
                  plan.totalBudgetedExpense +
                  plan.totalPlannedDebts +
                  linkedWalletsTotal;
              final unallocated = totalIncome - totalAllocated;

              // حساب الادخار (يمكن ربطه لاحقاً بقيمة محفظة التوفير المتوقعة أو أي مخصص ادخاري)
              const savings = 0.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    // 1. الهيدر البنفسجي
                    _buildHeaderCard(
                      totalIncome,
                      totalAllocated,
                      unallocated,
                      savings,
                    ),
                    24.verticalSpace,

                    _buildSection(
                      context: context,
                      title: 'مصادر الدخل',
                      buttonColor: const Color(0xFF00A86B),
                      isEmpty: plan.incomes.isEmpty,
                      emptyText: 'لم يتم إضافة مصادر دخل بعد',
                      onAdd: () => _showAddEditIncomeDialog(context, plan),
                      child: Column(
                        children: plan.incomes
                            .map((i) => _buildIncomeItem(context, i, plan))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    // 3. المخصصات (الفئات)
                    _buildSection(
                      context: context,
                      title: 'المخصصات',
                      buttonColor: const Color(0xFF2962FF),
                      isEmpty: plan.expenses.isEmpty,
                      emptyText: 'لم يتم إضافة مخصصات بعد',
                      onAdd: () => _showAddEditAllocationDialog(context, plan),
                      child: Column(
                        children: plan.expenses
                            .map((e) => _buildAllocationItem(context, e, plan))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    // 4. المحافظ المرتبطة
                    _buildSection(
                      context: context,
                      title: 'المحافظ المرتبطة',
                      buttonColor: const Color(0xFF009688),
                      isEmpty: linkedWallets.isEmpty,
                      emptyText: 'لم يتم إضافة محافظ مرتبطة بعد',
                      onAdd: () => _showAddEditLinkedWalletDialog(context),
                      child: Column(
                        children: linkedWallets
                            .map((w) => _buildWalletItem(context, w))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    // 5. الديون والمتكررة
                    _buildSection(
                      context: context,
                      title: 'الديون والمتكررة',
                      buttonColor: const Color(0xFFFF5A00),
                      isEmpty: plan.debts.isEmpty,
                      emptyText: 'لم يتم إضافة ديون أو معاملات متكررة بعد',
                      onAdd: () => _showAddEditDebtDialog(context, plan),
                      child: Column(
                        children: plan.debts
                            .map((d) => _buildDebtItem(context, d, plan))
                            .toList(),
                      ),
                    ),
                    40.verticalSpace,

                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 50.h,
                    //   child: ElevatedButton(
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFF00A86B),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8.r),
                    //       ),
                    //     ),
                    //     onPressed: () =>
                    //         context.read<MonthlyPlanCubit>().saveCurrentPlan(),
                    //     child: const Text(
                    //       'حفظ الميزانية',
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    //  20.verticalSpace,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    double income,
    double allocated,
    double unallocated,
    double savings,
  ) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFF7B42F6),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // العمود اليمين (الدخل وغير المخصص)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الدخل',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                Text(
                  income.toStringAsFixed(2),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                16.verticalSpace,
                Text(
                  'غير المخصص',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                Text(
                  unallocated.toStringAsFixed(2),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // العمود اليسار (المخصص والادخار)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'إجمالي المخصص',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                Text(
                  allocated.toStringAsFixed(2),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                16.verticalSpace,
                Text(
                  'الادخار',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                Text(
                  savings.toStringAsFixed(2),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Color buttonColor,
    required bool isEmpty,
    required String emptyText,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('إضافة', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                minimumSize: Size(80.w, 36.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        12.verticalSpace,
        if (isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Text(
                emptyText,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
            ),
          )
        else
          child,
      ],
    );
  }

  // --- عناصر القوائم ---
  // --- عناصر القوائم ---
  Widget _buildIncomeItem(
    BuildContext context,
    PlannedIncome item,
    MonthlyPlan plan,
  ) {
    final isDefault = item.id == 'default_salary';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: const Color(0xFF00A86B), size: 28.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    if (isDefault)
                      Text(
                        ' (افتراضي)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
                4.verticalSpace,
                // عرض تفاصيل الاستلام حسب هل هو ثابت أم متغير
                Text(
                  item.isFixed
                      ? 'يوم ${item.executionDay} - ${item.executionType.label}'
                      : 'غير محدد اليوم - يدوي',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          // عرض المبلغ لو ثابت، ولو غير ثابت نكتب "متغير"
          Text(
            item.isFixed ? item.amount.toStringAsFixed(2) : 'متغير',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: item.isFixed ? 18.sp : 14.sp,
              color: item.isFixed ? Colors.blue.shade900 : Colors.grey.shade600,
            ),
          ),
          16.horizontalSpace,

          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditIncomeDialog(context, plan, itemToEdit: item),
          ),

          if (!isDefault) ...[
            12.horizontalSpace,
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                final newIncomes = plan.incomes
                    .where((i) => i.id != item.id)
                    .toList();
                context.read<MonthlyPlanCubit>().updatePlan(
                  plan.copyWith(incomes: newIncomes),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationItem(
    BuildContext context,
    PlannedExpense item,
    MonthlyPlan plan,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card, color: Colors.blue.shade700, size: 24.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,
                Text(
                  item.endOfMonthAction.label,
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            item.budgetedAmount.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditAllocationDialog(context, plan, itemToEdit: item),
          ),
          12.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              final newExpenses = plan.expenses
                  .where((e) => e.id != item.id)
                  .toList();
              context.read<MonthlyPlanCubit>().updatePlan(
                plan.copyWith(expenses: newExpenses),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(BuildContext context, Wallet w) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade50,
            child: const Icon(Icons.account_balance_wallet, color: Colors.teal),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'يوم ${w.executionDay ?? 1} - ${_getExecutionTypeName(w.executionType)}',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            w.monthlyAmount?.toStringAsFixed(2) ?? '0.00',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditLinkedWalletDialog(context, walletToEdit: w),
          ),
          12.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<WalletCubit>().deleteWallet(w.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(
    BuildContext context,
    PlannedDebt item,
    MonthlyPlan plan,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: const Color(0xFFFF5A00),
            size: 24.r,
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'يوم ${item.executionDay} - ${item.executionType.label}',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            item.amount.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditDebtDialog(context, plan, itemToEdit: item),
          ),
          12.horizontalSpace,
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              final newDebts = plan.debts
                  .where((d) => d.id != item.id)
                  .toList();
              context.read<MonthlyPlanCubit>().updatePlan(
                plan.copyWith(debts: newDebts),
              );
            },
          ),
        ],
      ),
    );
  }

  // الدالة المساعدة لترجمة اسم النوع
  String _getExecutionTypeName(ExecutionType type) {
    switch (type) {
      case ExecutionType.auto:
        return 'تلقائي';
      case ExecutionType.confirm:
        return 'تأكيد';
      case ExecutionType.manual:
        return 'يدوي';
      default:
        return 'بدون';
    }
  }

  void _showAddEditAllocationDialog(
    BuildContext context,
    MonthlyPlan plan, {
    PlannedExpense? itemToEdit,
  }) {
    final isEdit = itemToEdit != null;

    _showGenericDialog(
      context,
      isEdit ? 'تعديل مخصص' : 'إضافة مخصص',
      (name, amount, day, type, sourceId, endAction, isFixed, targetWalletId) {
        // --- الربط السحري بين الميزانية وشاشة إضافة المعاملة ---
        final txCubit = context.read<TransactionCubit>();

        // 1. نبحث هل الفئة دي موجودة أصلاً في الفئات ولا لأ؟ (بالاسم والنوع)
        var category = txCubit.state.allCategories
            .where((c) => c.name == name && c.type == TransactionType.expense)
            .firstOrNull;

        // 2. لو مش موجودة، نكريتها تلقائياً عشان تظهر في شاشة المعاملات
        if (category == null) {
          category = TransactionCategory(
            id: const Uuid().v4(),
            name: name,
            type: TransactionType.expense,
            colorValue: Colors.blue.value, // لون افتراضي للفئات الجديدة
          );
          txCubit.addCategory(category);
        }

        // 3. نحفظ المخصص في الخطة بالـ ID الحقيقي بتاع الفئة
        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            categoryId: category.id,
            budgetedAmount: amount,
            sourceId: sourceId,
            endOfMonthAction: endAction,
          );
          final newList = plan.expenses
              .map((e) => e.id == updated.id ? updated : e)
              .toList();
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(expenses: newList),
          );
        } else {
          final newExpense = PlannedExpense(
            id: const Uuid().v4(),
            name: name,
            categoryId: category.id,
            budgetedAmount: amount,
            sourceId: sourceId,
            endOfMonthAction: endAction,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(expenses: [...plan.expenses, newExpense]),
          );
        }
      },
      showIncomeSource: true,
      showEndOfMonth: true,
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.budgetedAmount,
      initialSourceId: itemToEdit?.sourceId,
      initialEndAction: itemToEdit?.endOfMonthAction,
    );
  }

  void _showAddEditIncomeDialog(
    BuildContext context,
    MonthlyPlan plan, {
    PlannedIncome? itemToEdit,
  }) {
    final isEdit = itemToEdit != null;
    final isDefault = itemToEdit?.id == 'default_salary';

    _showGenericDialog(
      context,
      isEdit ? 'تعديل مصدر دخل' : 'إضافة مصدر دخل',
      (name, amount, day, type, sourceId, endAction, isFixed, targetWalletId) {
        // --- الربط مع فئات الدخل ---
        final txCubit = context.read<TransactionCubit>();
        var category = txCubit.state.allCategories
            .where((c) => c.name == name && c.type == TransactionType.income)
            .firstOrNull;

        if (category == null) {
          category = TransactionCategory(
            id: const Uuid().v4(),
            name: name,
            type: TransactionType.income,
            colorValue: Colors.green.value,
          );
          txCubit.addCategory(category);
        }

        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            amount: amount,
            executionDay: day,
            executionType: type,
            isFixed: isFixed,
            targetWalletId: targetWalletId,
          );
          final newIncomes = plan.incomes
              .map((i) => i.id == updated.id ? updated : i)
              .toList();
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(incomes: newIncomes),
          );
        } else {
          final newIncome = PlannedIncome(
            id: const Uuid().v4(),
            name: name,
            amount: amount,
            date: DateTime.now(),
            executionDay: day,
            executionType: type,
            isFixed: isFixed,
            targetWalletId: targetWalletId,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(incomes: [...plan.incomes, newIncome]),
          );
        }
      },
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.amount,
      initialDay: itemToEdit?.executionDay,
      initialType: itemToEdit?.executionType,
      initialIsFixed: itemToEdit?.isFixed,
      initialTargetWalletId: itemToEdit?.targetWalletId,
      nameEnabled: !isDefault,
      showFixedOption: true,
      showDepositWallet: true,
    );
  }

  void _showAddEditLinkedWalletDialog(
    BuildContext context, {
    Wallet? walletToEdit,
  }) {
    final isEdit = walletToEdit != null;

    _showGenericDialog(
      context,
      isEdit ? 'تعديل محفظة مرتبطة' : 'إضافة محفظة مرتبطة',
      (name, amount, day, type, sourceId, endAction, isFixed, targetWalletId) {
        final executionTypeEnum = ExecutionType.values.firstWhere(
          (e) => e.name == type.name,
          orElse: () => ExecutionType.confirm,
        );

        if (isEdit) {
          final updated = walletToEdit.copyWith(
            name: name,
            monthlyAmount: amount,
            executionDay: day,
            executionType: executionTypeEnum,
            sourceWalletId: sourceId,
          );
          context.read<WalletCubit>().updateWallet(updated);
        } else {
          final newWallet = Wallet(
            id: const Uuid().v4(),
            name: name,
            balance: 0.0,
            type: WalletType.sideLinked,
            monthlyAmount: amount,
            executionDay: day,
            executionType: executionTypeEnum,
            sourceWalletId: sourceId,
          );
          context.read<WalletCubit>().addWallet(newWallet);
        }
      },
      showIncomeSource: true,
      initialName: walletToEdit?.name,
      initialAmount: walletToEdit?.monthlyAmount,
      initialDay: walletToEdit?.executionDay,
      initialSourceId: walletToEdit?.sourceWalletId,
      initialType: walletToEdit != null
          ? PlanExecutionType.values.firstWhere(
              (e) => e.name == walletToEdit.executionType.name,
              orElse: () => PlanExecutionType.confirm,
            )
          : null,
    );
  }

  void _showAddEditDebtDialog(
    BuildContext context,
    MonthlyPlan plan, {
    PlannedDebt? itemToEdit,
  }) {
    final isEdit = itemToEdit != null;

    _showGenericDialog(
      context,
      isEdit ? 'تعديل دين أو معاملة متكررة' : 'إضافة دين أو معاملة متكررة',
      (name, amount, day, type, sourceId, endAction, isFixed, targetWalletId) {
        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            amount: amount,
            executionDay: day,
            executionType: type,
            sourceId: sourceId,
          );
          final newList = plan.debts
              .map((d) => d.id == updated.id ? updated : d)
              .toList();
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(debts: newList),
          );
        } else {
          final newDebt = PlannedDebt(
            id: const Uuid().v4(),
            name: name,
            amount: amount,
            executionDay: day,
            executionType: type,
            sourceId: sourceId,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(debts: [...plan.debts, newDebt]),
          );
        }
      },
      showIncomeSource: true,
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.amount,
      initialDay: itemToEdit?.executionDay,
      initialType: itemToEdit?.executionType,
      initialSourceId: itemToEdit?.sourceId,
    );
  }

  // الدالة الديناميكية المحدثة
  void _showGenericDialog(
    BuildContext context,
    String title,
    Function(
      String name,
      double amount,
      int day,
      PlanExecutionType type,
      String? sourceId,
      EndOfMonthAction endAction,
      bool isFixed,
      String? targetWalletId,
    )
    onSave, {
    bool showIncomeSource = false,
    bool showEndOfMonth = false,
    bool showFixedOption = false,
    bool showDepositWallet = false,
    String? initialName,
    double? initialAmount,
    int? initialDay,
    PlanExecutionType? initialType,
    String? initialSourceId,
    EndOfMonthAction? initialEndAction,
    bool? initialIsFixed,
    String? initialTargetWalletId,
    bool nameEnabled = true,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final amountCtrl = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? initialAmount.toString()
          : '',
    );
    final dayCtrl = TextEditingController(text: initialDay?.toString() ?? '1');
    var selectedType = initialType ?? PlanExecutionType.manual;
    var selectedEndAction = initialEndAction ?? EndOfMonthAction.keepRemaining;
    var selectedSourceId = initialSourceId;
    var selectedTargetWalletId = initialTargetWalletId;
    var isFixed = initialIsFixed ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final incomes =
                context.read<MonthlyPlanCubit>().state.plan?.incomes ?? [];
            final wallets =
                (context.read<WalletCubit>().state as WalletLoaded).wallets;

            // تحديد المحفظة الافتراضية إذا لم تكن محددة مسبقاً (محفظة الميزانية)
            if (selectedTargetWalletId == null && wallets.isNotEmpty) {
              selectedTargetWalletId = wallets
                  .firstWhere(
                    (w) => w.type == WalletType.mainBudget,
                    orElse: () => wallets.first,
                  )
                  .id;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    20.verticalSpace,

                    TextFormField(
                      controller: nameCtrl,
                      enabled: nameEnabled,
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        filled: true,
                        fillColor: nameEnabled
                            ? Colors.grey.shade50
                            : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    10.verticalSpace,

                    if (showFixedOption) ...[
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('مبلغ ثابت'),
                              value: true,
                              groupValue: isFixed,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => isFixed = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('غير ثابت (متغير)'),
                              value: false,
                              groupValue: isFixed,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() {
                                isFixed = v!;
                                selectedType = PlanExecutionType
                                    .manual; // إجبار النوع على يدوي
                              }),
                            ),
                          ),
                        ],
                      ),
                      10.verticalSpace,
                    ],

                    // إخفاء هذه الحقول إذا كان الدخل غير ثابت
                    if (isFixed) ...[
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      10.verticalSpace,

                      if (!showEndOfMonth) ...[
                        TextFormField(
                          controller: dayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'يوم التنفيذ',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        10.verticalSpace,
                        DropdownButtonFormField<PlanExecutionType>(
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            labelText: 'النوع',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: PlanExecutionType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedType = v!),
                        ),
                        10.verticalSpace,
                      ],
                    ],

                    // محفظة الإيداع (تظهر دائماً للدخل لتعرف أين ستذهب الأموال)
                    if (showDepositWallet) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedTargetWalletId,
                        decoration: InputDecoration(
                          labelText: 'محفظة الإيداع (أين سيتم حفظ الأموال؟)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: wallets
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedTargetWalletId = v),
                      ),
                      10.verticalSpace,
                    ],

                    if (showIncomeSource) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedSourceId,
                        decoration: InputDecoration(
                          labelText: 'مصدر الفلوس',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: incomes
                            .map(
                              (i) => DropdownMenuItem(
                                value: i.id,
                                child: Text(i.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedSourceId = v),
                      ),
                      10.verticalSpace,
                    ],

                    if (showEndOfMonth) ...[
                      DropdownButtonFormField<EndOfMonthAction>(
                        initialValue: selectedEndAction,
                        decoration: InputDecoration(
                          labelText: 'إعدادات نهاية الشهر',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: EndOfMonthAction.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedEndAction = v!),
                      ),
                      10.verticalSpace,
                    ],
                    20.verticalSpace,

                    ElevatedButton(
                      onPressed: () {
                        // إذا كان غير ثابت، نعتبر المبلغ 0 واليوم 1 افتراضياً لتجنب الأخطاء
                        final amount = isFixed
                            ? (double.tryParse(amountCtrl.text) ?? 0.0)
                            : 0.0;
                        final day = isFixed
                            ? (int.tryParse(dayCtrl.text) ?? 1)
                            : 1;
                        final type = isFixed
                            ? selectedType
                            : PlanExecutionType.manual;

                        if (nameCtrl.text.isNotEmpty &&
                            (amount >= 0 || !isFixed)) {
                          onSave(
                            nameCtrl.text,
                            amount,
                            day,
                            type,
                            selectedSourceId,
                            selectedEndAction,
                            isFixed,
                            selectedTargetWalletId,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    10.verticalSpace,
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // void _showAddIncomeDialog(BuildContext context, MonthlyPlan plan) {
  //   _showGenericDialog(context, 'إضافة مصدر دخل', (
  //     name,
  //     amount,
  //     day,
  //     type,
  //     sourceId,
  //     endAction,
  //     isFixed,
  //     targetWalletId,
  //   ) {
  //     final newIncome = PlannedIncome(
  //       id: const Uuid().v4(),
  //       name: name,
  //       amount: amount,
  //       date: DateTime.now(),
  //       executionDay: day,
  //       executionType: type,
  //       isFixed: isFixed,
  //       targetWalletId: targetWalletId,
  //     );
  //     context.read<MonthlyPlanCubit>().updatePlan(
  //       plan.copyWith(incomes: [...plan.incomes, newIncome]),
  //     );
  //   });
  // }
}
