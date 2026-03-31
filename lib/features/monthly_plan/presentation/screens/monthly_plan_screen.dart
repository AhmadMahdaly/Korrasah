import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/shared_widgets/custom_primary_button.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/core/theme/themes.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/monthly_plan/presentation/screens/setup_monthly_plan_screen.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

class MonthlyPlanScreen extends StatelessWidget {
  const MonthlyPlanScreen({super.key});

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
        heightBar: 80.h,
        title: 'الميزانية',
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, planState) {
          if (planState.status == MonthlyPlanStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentMonth = planState.currentMonth;
          final plan = planState.plan;

          return Column(
            children: [
              _buildMonthSelector(context, currentMonth),

              Expanded(
                child: plan == null
                    ? const SizedBox()
                    : BlocBuilder<WalletCubit, WalletState>(
                        builder: (context, walletState) {
                          final wallets = (walletState is WalletLoaded)
                              ? walletState.wallets
                              : <Wallet>[];
                          final linkedWallets = wallets
                              .where((w) => w.type == WalletType.sideLinked)
                              .toList();

                          final hasRealIncome = plan.incomes.any(
                            (i) => i.id != 'default_salary' || i.amount > 0,
                          );
                          final isPlanEmpty = !hasRealIncome || !plan.isStarted;

                          if (isPlanEmpty) {
                            return _buildEmptyState(context);
                          }

                          return BlocBuilder<
                            TransactionCubit,
                            TransactionState
                          >(
                            builder: (context, txState) {
                              return _buildPopulatedState(
                                context,
                                plan,
                                linkedWallets,
                                txState.allTransactions,
                                currentMonth,
                                txState.allCategories,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime currentMonth) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(20)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.r,
              color: AppColors.primaryTextColor,
            ),
            onPressed: () {
              final prevMonth = DateTime(
                currentMonth.year,
                currentMonth.month - 1,
                1,
              );
              context.read<MonthlyPlanCubit>().loadPlanForMonth(prevMonth);
            },
          ),

          Text(
            '${_getMonthArabicName(currentMonth.month)} ${currentMonth.year}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,

              size: 18.r,
              color: AppColors.primaryTextColor,
            ),
            onPressed: () {
              final nextMonth = DateTime(
                currentMonth.year,
                currentMonth.month + 1,
                1,
              );
              context.read<MonthlyPlanCubit>().loadPlanForMonth(nextMonth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24.r),
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40.r,
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                Icons.show_chart,
                size: 40.r,
                color: Colors.grey.shade400,
              ),
            ),
            24.verticalSpace,
            Text(
              'لم يتم إعداد الميزانية',
              style: AppTextStyle.style20Bold.copyWith(
                color: Colors.black87,
              ),
            ),
            12.verticalSpace,
            Text(
              'قم بإعداد ميزانيتك الشهرية أولاً',
              style: AppTextStyle.style14W500.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            32.verticalSpace,
            CustomPrimaryButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SetupMonthlyPlanScreen(),
                  ),
                );
              },
              text: 'إعداد الميزانية',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState(
    BuildContext context,
    MonthlyPlan plan,
    List<Wallet> linkedWallets,
    List<Transaction> allTxs,
    DateTime currentMonth,
    List<TransactionCategory> allCategories,
  ) {
    final startDate = DateTime(currentMonth.year, currentMonth.month, 1);
    final endDate = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final dateRangeStr =
        'من ${startDate.day} ${_getMonthArabicName(startDate.month)} إلى ${endDate.day} ${_getMonthArabicName(endDate.month)}';

    final totalPlannedIncome = plan.totalPlannedIncome;

    final actualTotalExpenses = allTxs
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.year == currentMonth.year &&
              t.date.month == currentMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final remainingFromIncome = totalPlannedIncome - actualTotalExpenses;
    final overallProgress = totalPlannedIncome > 0
        ? (actualTotalExpenses / totalPlannedIncome).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 14.r,
                      color: AppColors.primaryColor,
                    ),
                    6.horizontalSpace,
                    Text(
                      dateRangeStr,
                      style: AppTextStyle.style12Bold.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.setupMonthlyPlanScreen),
                icon: Icon(
                  Icons.edit,
                  color: AppColors.primaryTextColor,
                  size: 14.r,
                ),
                label: Text(
                  'تعديل الخطة',
                  style: AppTextStyle.style12Bold.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,

          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: appGradient(),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'الباقي من الدخل',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                4.verticalSpace,
                Text(
                  '${remainingFromIncome.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                16.verticalSpace,
                LinearProgressIndicator(
                  value: overallProgress,
                  backgroundColor: Colors.white.withAlpha(55),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                16.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.call_made,
                              color: Colors.white70,
                              size: 14.r,
                            ),
                            4.horizontalSpace,
                            Text(
                              'المصروفات',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          actualTotalExpenses.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.call_received,
                              color: Colors.white70,
                              size: 14.r,
                            ),
                            4.horizontalSpace,
                            Text(
                              'الدخل المخطط',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          totalPlannedIncome.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          24.verticalSpace,

          if (plan.expenses.isNotEmpty) ...[
            Text(
              'المخصصات',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            12.verticalSpace,
            ...plan.expenses.map(
              (expense) => _buildAllocationProgressTile(
                context,
                expense,
                allTxs,
                currentMonth,
                allCategories,
              ),
            ),
            24.verticalSpace,
          ],

          if (linkedWallets.isNotEmpty) ...[
            Text(
              'المحافظ المرتبطة',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            12.verticalSpace,
            ...linkedWallets.map(_buildWalletTile),
            24.verticalSpace,
          ],

          if (plan.debts.isNotEmpty) ...[
            Text(
              'الديون والمتكررة',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            12.verticalSpace,
            ...plan.debts.map(_buildDebtTile),
            30.verticalSpace,
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationProgressTile(
    BuildContext context,
    PlannedExpense expense,
    List<Transaction> allTxs,
    DateTime currentMonth,
    List<TransactionCategory> allCategories,
  ) {
    final budgeted = expense.budgetedAmount;
    final subCategories = allCategories
        .where((TransactionCategory? c) => c?.parentId == expense.categoryId)
        .map((TransactionCategory? c) => c?.id ?? '')
        .where((String id) => id.isNotEmpty)
        .toList();
    final relevantIds = [expense.categoryId, ...subCategories];

    final actualSpent = allTxs
        .where(
          (t) =>
              relevantIds.contains(t.categoryId) &&
              t.type == TransactionType.expense &&
              t.date.year == currentMonth.year &&
              t.date.month == currentMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final remaining = budgeted - actualSpent;
    final progress = budgeted > 0
        ? (actualSpent / budgeted).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = remaining < 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: Colors.black12),
      ),
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showTransactionsBottomSheet(
          context,
          expense.name,
          relevantIds,
          currentMonth,
        ),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget
                              ? Colors.red
                              : AppColors.primaryTextColor,
                        ),
                      ),
                      Text(
                        isOverBudget ? 'متجاوز' : 'متبقي',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            expense.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          8.horizontalSpace,
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12.r,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      Text(
                        'صُرف ${actualSpent.toStringAsFixed(2)} من ${budgeted.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              12.verticalSpace,
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : AppColors.primaryTextColor,
                ),
                minHeight: 6.h,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletTile(Wallet wallet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: Colors.black12),
      ),
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        title: Text(
          wallet.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${wallet.monthlyAmount?.toStringAsFixed(2)} ج.م شهرياً',
        ),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              wallet.balance.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'الرصيد',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: AppColors.primaryTextColor.withAlpha(55),
          child: const Icon(
            Icons.account_balance_wallet,
            color: AppColors.primaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDebtTile(PlannedDebt debt) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.red.shade100),
      ),
      color: Colors.red.shade50,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        title: Text(
          debt.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('يوم ${debt.executionDay} من كل شهر'),
        leading: Text(
          '-${debt.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        trailing: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.credit_card, color: Colors.red.shade700),
        ),
      ),
    );
  }

  void _showTransactionsBottomSheet(
    BuildContext context,
    String categoryName,
    List<String> relevantIds,
    DateTime currentMonth,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, txState) {
            final transactions = txState.allTransactions.where((t) {
              return relevantIds.contains(t.categoryId) &&
                  t.type == TransactionType.expense &&
                  t.date.year == currentMonth.year &&
                  t.date.month == currentMonth.month;
            }).toList()..sort((a, b) => b.date.compareTo(a.date));

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Expanded(
                    child: transactions.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد عمليات مسجلة في $categoryName خلال ${_getMonthArabicName(currentMonth.month)}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) =>
                                12.verticalSpace,
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              final dateStr =
                                  '${_getMonthArabicName(tx.date.month)} ${tx.date.year} ${tx.date.day}';
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (tx.note != null &&
                                                  tx.note!.isNotEmpty)
                                              ? tx.note!
                                              : 'غير محدد',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        4.verticalSpace,
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '-${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
}
