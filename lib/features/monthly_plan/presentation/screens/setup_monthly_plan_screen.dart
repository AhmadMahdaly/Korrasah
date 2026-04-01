// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/custom_primary_button.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/core/theme/themes.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/transactions/presentation/screens/widgets/recurrence_selector.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';
import 'package:uuid/uuid.dart';

class SetupMonthlyPlanScreen extends StatelessWidget {
  const SetupMonthlyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: true,
        heightBar: 80.h,
        title: 'إعداد الميزانية',
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

              final savingsWallet = wallets.firstWhere(
                (w) => w.type == WalletType.savings,
                orElse: () =>
                    const Wallet(id: 's', name: 'التوفير', balance: 0),
              );
              final linkedWallets = wallets
                  .where((w) => w.type == WalletType.sideLinked)
                  .toList();

              final totalIncome = plan.totalPlannedIncome;
              final linkedWalletsTotal = linkedWallets.fold(
                0.0,
                (s, w) => s + (w.monthlyAmount ?? 0),
              );
              final savingsTotal = savingsWallet.monthlyAmount ?? 0.0;
              final totalAllocated =
                  plan.totalBudgetedExpense +
                  plan.totalPlannedDebts +
                  linkedWalletsTotal +
                  savingsTotal;
              final unallocated = totalIncome - totalAllocated;

              final currentMonth = planState.currentMonth;
              final startDate = DateTime(
                currentMonth.year,
                currentMonth.month,
                1,
              );
              final endDate = DateTime(
                currentMonth.year,
                currentMonth.month + 1,
                0,
              );
              final dateRangeStr =
                  'فترة الخطة: ${startDate.day} ${_getMonthArabicName(startDate.month)} إلى ${endDate.day} ${_getMonthArabicName(endDate.month)}';

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 36.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 16.r,
                            color: AppColors.primaryColor,
                          ),
                          8.horizontalSpace,
                          Text(
                            dateRangeStr,
                            style: AppTextStyle.style12Bold.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    16.verticalSpace,

                    _buildHeaderCard(
                      totalIncome,
                      totalAllocated,
                      unallocated,
                      savingsTotal,
                    ),
                    24.verticalSpace,

                    _buildSection(
                      context: context,
                      title: 'مصادر الدخل',
                      isEmpty: plan.incomes.isEmpty,
                      emptyText: 'لم يتم إضافة مصادر دخل',
                      onAdd: () =>
                          _showAddEditIncomeDialog(context, false, plan),
                      child: Column(
                        children: plan.incomes
                            .map((i) => _buildIncomeItem(context, i, plan))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الادخار والتوفير',
                          style: AppTextStyle.style18Bold,
                        ),
                        12.verticalSpace,
                        _buildFixedSavingsItem(context, savingsWallet),
                      ],
                    ),
                    24.verticalSpace,

                    _buildSection(
                      context: context,
                      title: 'المخصصات',
                      isEmpty: plan.expenses.isEmpty,
                      emptyText: 'لم يتم إضافة مخصصات',
                      onAdd: () => _showAddEditAllocationDialog(context, plan),
                      child: Column(
                        children: plan.expenses
                            .map((e) => _buildAllocationItem(context, e, plan))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    _buildSection(
                      context: context,
                      title: 'المحافظ المرتبطة',
                      isEmpty: linkedWallets.isEmpty,
                      emptyText: 'لم يتم إضافة محافظ مرتبطة',
                      onAdd: () => _showAddEditLinkedWalletDialog(context),
                      child: Column(
                        children: linkedWallets
                            .map((w) => _buildWalletItem(context, w))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    _buildSection(
                      context: context,
                      title: 'الديون والمتكررة',
                      isEmpty: plan.debts.isEmpty,
                      emptyText: 'لم يتم إضافة ديون',
                      onAdd: () => _showAddEditDebtDialog(context, plan),
                      child: Column(
                        children: plan.debts
                            .map((d) => _buildDebtItem(context, d, plan))
                            .toList(),
                      ),
                    ),
                    40.verticalSpace,

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unallocated < 0
                              ? AppColors.errorColor
                              : AppColors.secondaryTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () {
                          if (unallocated < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'الميزانية بالسالب! قم بتعديل المخصصات أولاً.',
                                ),
                              ),
                            );
                            return;
                          }
                          context.read<MonthlyPlanCubit>()
                            ..updatePlan(plan.copyWith(isStarted: true))
                            ..saveCurrentPlan();
                          Navigator.pop(context);
                        },
                        label: Text(
                          plan.isStarted
                              ? 'تحديث الخطة'
                              : 'تأكيد التوزيع - بدء الخطة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    20.verticalSpace,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFixedSavingsItem(BuildContext context, Wallet savingsWallet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.savings, color: const Color(0xFFFF7A00), size: 28.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'الادخار الشهري',
                      style: AppTextStyle.style14Bold.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      ' (أساسي)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                4.verticalSpace,
                Text(
                  'هدف يتم ترحيله للتوفير',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            savingsWallet.monthlyAmount?.toStringAsFixed(2) ?? '0.00',
            style: AppTextStyle.style16Bold.copyWith(
              color: Colors.orange.shade900,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(
              CupertinoIcons.square_pencil,
              color: AppColors.primaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditSavingsDialog(context, savingsWallet),
          ),
        ],
      ),
    );
  }

  String _getMonthArabicName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  void _showEditSavingsDialog(BuildContext context, Wallet savingsWallet) {
    _showGenericDialog(
      context,
      'تحديد هدف الادخار الشهري',
      null,
      (
        name,
        amount,
        type,
        recurrenceType,
        selectedDays,
        sourceId,
        endAction,
        isFixed,
        targetWalletId,
      ) {
        final updated = savingsWallet.copyWith(monthlyAmount: amount);
        context.read<WalletCubit>().updateWallet(updated);
      },
      initialName: 'محفظة التوفير',
      initialAmount: savingsWallet.monthlyAmount,
      nameEnabled: false,
      showEndOfMonth: false,
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
        gradient: appGradient(),

        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
              style: AppTextStyle.style18Bold.copyWith(
                color: AppColors.secondaryTextColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: Text(
                'إضافة',
                style: AppTextStyle.style12W500.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
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
          Icon(
            CupertinoIcons.money_dollar_circle,
            color: AppColors.primaryColor,
            size: 28.r,
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: AppTextStyle.style16Bold),
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

                Text(
                  item.isFixed
                      ? 'يوم ${item.executionDay} - ${item.executionType.label}'
                      : 'غير محدد اليوم - يدوي',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          Text(
            item.isFixed ? item.amount.toStringAsFixed(2) : 'متغير',
            style: AppTextStyle.style16Bold.copyWith(
              fontSize: item.isFixed ? 16.sp : 14.sp,
              color: item.isFixed
                  ? AppColors.primaryTextColor
                  : AppColors.secondaryTextColor,
            ),
          ),
          16.horizontalSpace,

          IconButton(
            icon: const Icon(
              CupertinoIcons.square_pencil,
              color: AppColors.primaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showAddEditIncomeDialog(
              context,
              isDefault,
              plan,
              itemToEdit: item,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(
    BuildContext context,
    PlannedExpense item,
    MonthlyPlan plan,
  ) {
    final wallets = (context.read<WalletCubit>().state as WalletLoaded).wallets;
    final walletName = item.walletId == null
        ? 'الميزانية الرئيسية'
        : wallets
              .firstWhere(
                (w) => w.id == item.walletId,
                orElse: () =>
                    const Wallet(id: '', name: 'محفظة مجهولة', balance: 0),
              )
              .name;

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
          Icon(Icons.credit_card, color: Colors.black87, size: 24.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyle.style14Bold.copyWith(
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,

                Text(
                  '${item.endOfMonthAction.label} • $walletName',
                  style: AppTextStyle.style12W500.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            item.budgetedAmount.toStringAsFixed(2),
            style: AppTextStyle.style14Bold.copyWith(
              color: Colors.black87,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(
              CupertinoIcons.square_pencil,
              color: AppColors.primaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditAllocationDialog(context, plan, itemToEdit: item),
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
                  style: AppTextStyle.style14Bold.copyWith(
                    color: Colors.black87,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'يوم ${w.executionDay ?? 1} - ${_getExecutionTypeName(w.executionType)}',
                  style: AppTextStyle.style12W500.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            w.monthlyAmount?.toStringAsFixed(2) ?? '0.00',
            style: AppTextStyle.style14Bold.copyWith(
              color: Colors.black87,
            ),
          ),
          16.horizontalSpace,
          IconButton(
            icon: const Icon(
              CupertinoIcons.square_pencil,
              color: AppColors.primaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditLinkedWalletDialog(context, walletToEdit: w),
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
            icon: const Icon(
              CupertinoIcons.square_pencil,
              color: AppColors.primaryColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                _showAddEditDebtDialog(context, plan, itemToEdit: item),
          ),
        ],
      ),
    );
  }

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
      isEdit
          ? IconButton(
              icon: const Icon(
                CupertinoIcons.delete_simple,
                color: Colors.red,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final newExpenses = plan.expenses
                    .where((e) => e.id != itemToEdit.id)
                    .toList();
                await context.read<MonthlyPlanCubit>().updatePlan(
                  plan.copyWith(expenses: newExpenses),
                );
                context.pop();
              },
            )
          : null,
      (
        name,
        amount,
        type,
        recurrenceType,
        selectedDays,
        sourceId,
        endAction,
        isFixed,
        targetWalletId,
      ) {
        final txCubit = context.read<TransactionCubit>();
        var category = txCubit.state.allCategories
            .where((c) => c.name == name && c.type == TransactionType.expense)
            .firstOrNull;

        if (category == null) {
          category = TransactionCategory(
            id: const Uuid().v4(),
            name: name,
            type: TransactionType.expense,
            colorValue: Colors.blue.value,
          );
          txCubit.addCategory(category);
        }

        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            categoryId: category.id,
            budgetedAmount: amount,
            sourceId: sourceId,
            endOfMonthAction: endAction,
            walletId: targetWalletId,
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
            walletId: targetWalletId,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(expenses: [...plan.expenses, newExpense]),
          );
        }
      },
      showIncomeSource: true,
      showEndOfMonth: true,
      showExpenseWallet: true,
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.budgetedAmount,
      initialSourceId: itemToEdit?.sourceId,
      initialEndAction: itemToEdit?.endOfMonthAction,
      initialTargetWalletId: itemToEdit?.walletId,
    );
  }

  void _showAddEditIncomeDialog(
    BuildContext context,
    bool isDefault,
    MonthlyPlan plan, {
    PlannedIncome? itemToEdit,
  }) {
    final isEdit = itemToEdit != null;
    final isDefault = itemToEdit?.id == 'default_salary';

    _showGenericDialog(
      context,
      isEdit ? 'تعديل مصدر دخل' : 'إضافة مصدر دخل',
      (isEdit && !isDefault)
          ? IconButton(
              icon: const Icon(CupertinoIcons.delete_simple, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final newIncomes = plan.incomes
                    .where((i) => i.id != itemToEdit.id)
                    .toList();
                await context.read<MonthlyPlanCubit>().updatePlan(
                  plan.copyWith(incomes: newIncomes),
                );
                context.pop();
              },
            )
          : null,
      (
        name,
        amount,
        type,
        recurrenceType,
        selectedDays,
        sourceId,
        endAction,
        isFixed,
        targetWalletId,
      ) {
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
            executionType: type,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
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
            executionType: type,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
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
      initialType: itemToEdit?.executionType,
      initialRecurrenceType: itemToEdit?.recurrenceType,
      initialSelectedDays: itemToEdit?.selectedDays,
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
      isEdit
          ? IconButton(
              icon: const Icon(CupertinoIcons.delete_simple, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                await context.read<WalletCubit>().deleteWallet(walletToEdit.id);
                context.pop();
              },
            )
          : null,
      (
        name,
        amount,
        type,
        recurrenceType,
        selectedDays,
        sourceId,
        endAction,
        isFixed,
        targetWalletId,
      ) {
        final executionTypeEnum = ExecutionType.values.firstWhere(
          (e) => e.name == type.name,
          orElse: () => ExecutionType.confirm,
        );

        if (isEdit) {
          final updated = walletToEdit.copyWith(
            name: name,
            monthlyAmount: amount,

            executionType: executionTypeEnum,
            sourceWalletId: sourceId,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
          );
          context.read<WalletCubit>().updateWallet(updated);
        } else {
          final newWallet = Wallet(
            id: const Uuid().v4(),
            name: name,
            balance: 0.0,
            type: WalletType.sideLinked,
            monthlyAmount: amount,
            executionType: executionTypeEnum,
            sourceWalletId: sourceId,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
          );
          context.read<WalletCubit>().addWallet(newWallet);
        }
      },
      showIncomeSource: true,
      initialName: walletToEdit?.name,
      initialAmount: walletToEdit?.monthlyAmount,

      initialSourceId: walletToEdit?.sourceWalletId,
      initialType: walletToEdit != null
          ? PlanExecutionType.values.firstWhere(
              (e) => e.name == walletToEdit.executionType.name,
              orElse: () => PlanExecutionType.confirm,
            )
          : null,
      initialRecurrenceType: walletToEdit?.recurrenceType,
      initialSelectedDays: walletToEdit?.selectedDays,
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
      isEdit
          ? IconButton(
              icon: const Icon(CupertinoIcons.delete_simple, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final newDebts = plan.debts
                    .where((d) => d.id != itemToEdit.id)
                    .toList();
                await context.read<MonthlyPlanCubit>().updatePlan(
                  plan.copyWith(debts: newDebts),
                );
                context.pop();
              },
            )
          : null,
      (
        name,
        amount,
        type,
        recurrenceType,
        selectedDays,
        sourceId,
        endAction,
        isFixed,
        targetWalletId,
      ) {
        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            amount: amount,
            executionType: type,
            sourceId: sourceId,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
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
            executionType: type,
            sourceId: sourceId,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(debts: [...plan.debts, newDebt]),
          );
        }
      },
      showIncomeSource: true,
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.amount,
      initialType: itemToEdit?.executionType,
      initialSourceId: itemToEdit?.sourceId,
      initialRecurrenceType: itemToEdit?.recurrenceType,
      initialSelectedDays: itemToEdit?.selectedDays,
    );
  }

  void _showGenericDialog(
    BuildContext context,
    String title,
    Widget? action,
    Function(
      String name,
      double amount,
      PlanExecutionType type,
      RecurrenceType recurrenceType,
      List<int> selectedDays,
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
    bool showExpenseWallet = false,
    String? initialName,
    double? initialAmount,
    PlanExecutionType? initialType,
    RecurrenceType? initialRecurrenceType,
    List<int>? initialSelectedDays,
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

    var selectedRecurrence = initialRecurrenceType ?? RecurrenceType.monthly;
    var currentSelectedDays = initialSelectedDays ?? [1];

    var selectedType = initialType ?? PlanExecutionType.manual;
    var selectedEndAction =
        initialEndAction ?? EndOfMonthAction.transferToSavings;
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

            if (showDepositWallet &&
                selectedTargetWalletId == null &&
                wallets.isNotEmpty) {
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
                  spacing: 4.h,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        action ?? 24.horizontalSpace,
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
                                selectedType = PlanExecutionType.manual;
                              }),
                            ),
                          ),
                        ],
                      ),
                      10.verticalSpace,
                    ],

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
                        RecurrenceSelector(
                          initialType: selectedRecurrence,
                          initialDays: currentSelectedDays,
                          onChanged: (type, days) {
                            setState(() {
                              selectedRecurrence = type;
                              currentSelectedDays = List.from(days);
                            });
                          },
                        ),
                        10.verticalSpace,

                        DropdownButtonFormField<PlanExecutionType>(
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            labelText: 'نوع التنفيذ (تأكيد/تلقائي)',
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

                    if (showExpenseWallet) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: selectedTargetWalletId,
                        decoration: InputDecoration(
                          labelText: 'تابع لميزانية أي محفظة؟',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('الميزانية الرئيسية'),
                          ),
                          ...wallets
                              .where(
                                (w) => w.type == WalletType.sideIndependent,
                              )
                              .map(
                                (w) => DropdownMenuItem<String?>(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              ),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedTargetWalletId = v),
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

                    CustomPrimaryButton(
                      onPressed: () {
                        final amount = isFixed
                            ? (double.tryParse(amountCtrl.text) ?? 0.0)
                            : 0.0;
                        final type = isFixed
                            ? selectedType
                            : PlanExecutionType.manual;

                        if (nameCtrl.text.isNotEmpty &&
                            (amount >= 0 || !isFixed)) {
                          onSave(
                            nameCtrl.text,
                            amount,
                            type,
                            selectedRecurrence,
                            currentSelectedDays,
                            selectedSourceId,
                            selectedEndAction,
                            isFixed,
                            selectedTargetWalletId,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      text: 'حفظ',
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
}
