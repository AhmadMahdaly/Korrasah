import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/services/app_settings_store.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/monthly_plan/domain/entities/budget_summary.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: false,
        heightBar: 86.h,
        title: 'الرئيسية',
        actions: [
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              final appSettings = AppSettingsStore(
                sharedPreferences: getIt(),
              );
              final pendingCount = state.pendingTransactions.length;
              return SizedBox(
                width: 46.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        context.pushNamed(AppRoutes.notificationsScreen);
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        size: 24.r,
                        color: AppColors.white,
                      ),
                    ),
                    if (appSettings.notificationsEnabled && pendingCount > 0)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(
                            color: AppColors.errorColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, planState) {
          final currentMonth = planState.currentMonth;
          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, transactionState) {
              return BlocBuilder<WalletCubit, WalletState>(
                builder: (context, walletState) {
                  final monthTransactions = _filterTransactionsForMonth(
                    transactionState.allTransactions,
                    currentMonth,
                  );
                  final wallets = walletState is WalletLoaded
                      ? walletState.wallets
                      : const <Wallet>[];
                  final linkedExpenses =
                      planState.plan?.expenses ?? const <PlannedExpense>[];

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<MonthlyPlanCubit>().loadPlanForMonth(
                        currentMonth,
                      );
                      await context.read<TransactionCubit>().loadInitialData();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                      children: [
                        _MonthSwitcher(currentMonth: currentMonth),
                        16.verticalSpace,
                        _HeroSummaryCard(
                          wallets: wallets,
                          summary: planState.summary,
                        ),
                        16.verticalSpace,
                        _SectionCard(
                          title: 'آخر المعاملات',
                          subtitle: 'آخر حركة خلال الشهر الحالي',
                          actionLabel: 'كل المعاملات',
                          onActionTap: () {
                            context.pushNamed(AppRoutes.transactionsScreen);
                          },
                          child: _RecentTransactionsList(
                            transactions: monthTransactions,
                            wallets: wallets,
                          ),
                        ),
                        16.verticalSpace,
                        _SectionCard(
                          title: 'تحليل المخصصات',
                          subtitle: 'المخطط مقابل المنصرف حتى الآن',
                          actionLabel: 'الميزانية',
                          onActionTap: () {
                            context.pushNamed(AppRoutes.budgetTrackingScreen);
                          },
                          child: _AllocationProgressList(
                            plannedExpenses: linkedExpenses,
                            transactions: monthTransactions,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Transaction> _filterTransactionsForMonth(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return transactions.where((transaction) {
      return transaction.date.year == month.year &&
          transaction.date.month == month.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.currentMonth});

  final DateTime currentMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoForward =
        currentMonth.year < now.year ||
        (currentMonth.year == now.year && currentMonth.month < now.month);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.black.withAlpha(18)),
      ),
      child: Row(
        children: [
          _MonthArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              context.read<MonthlyPlanCubit>().loadPlanForMonth(
                DateTime(currentMonth.year, currentMonth.month - 1, 1),
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'الشهر',
                  style: AppTextStyle.style12Bold.copyWith(
                    color: AppColors.textGreyColor,
                  ),
                ),
                4.verticalSpace,
                Text(
                  DateFormat('MMMM yyyy', 'ar').format(currentMonth),
                  style: AppTextStyle.style16W700.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          _MonthArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: canGoForward
                ? () {
                    context.read<MonthlyPlanCubit>().loadPlanForMonth(
                      DateTime(currentMonth.year, currentMonth.month + 1, 1),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.textGreyColor.withAlpha(20)
              : AppColors.primaryColor.withAlpha(18),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.textGreyColor
              : AppColors.primaryColor,
          size: 24.r,
        ),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.wallets,
    required this.summary,
  });

  final List<Wallet> wallets;
  final BudgetSummary? summary;

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsStore(sharedPreferences: getIt());
    final actualWalletBalance = wallets
        .where(
          (wallet) =>
              wallet.type != WalletType.savings && wallet.includeInTotal,
        )
        .fold<double>(0, (sum, wallet) => sum + wallet.balance);
    final savingsBalance = wallets
        .where((wallet) => wallet.type == WalletType.savings)
        .fold<double>(0, (sum, wallet) => sum + wallet.balance);
    final totalIncome = summary?.totalIncome ?? 0.0;
    final totalExpense = summary?.totalExpense ?? 0.0;
    final net = totalIncome - totalExpense;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E9F6E), Color(0xFF046C4E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF046C4E).withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صورة سريعة للشهر',
            style: AppTextStyle.style14W500.copyWith(
              color: Colors.white.withAlpha(220),
            ),
          ),
          10.verticalSpace,
          Text(
            appSettings.formatAmount(actualWalletBalance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          4.verticalSpace,
          Text(
            'إجمالي المحافظ الفعلية',
            style: AppTextStyle.style12Bold.copyWith(
              color: Colors.white.withAlpha(220),
            ),
          ),
          18.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _HeroStatTile(
                  title: 'صافي الشهر',
                  value: appSettings.formatAmount(net),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _HeroStatTile(
                  title: 'التوفير',
                  value: appSettings.formatAmount(savingsBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.style12Bold.copyWith(
              color: Colors.white.withAlpha(210),
            ),
          ),
          8.verticalSpace,
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withAlpha(15)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.style16W700.copyWith(
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      subtitle,
                      style: AppTextStyle.style12Bold.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  child: Text(
                    actionLabel!,
                    style: AppTextStyle.style12Bold.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          10.verticalSpace,
          child,
        ],
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList({
    required this.transactions,
    required this.wallets,
  });

  final List<Transaction> transactions;
  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsStore(sharedPreferences: getIt());
    final recentTransactions = transactions.take(5).toList();
    if (recentTransactions.isEmpty) {
      return const _EmptyStateBox(
        message: 'لا توجد معاملات مسجلة لهذا الشهر حتى الآن.',
      );
    }

    return Column(
      children: recentTransactions.map((transaction) {
        String? walletName;
        for (final wallet in wallets) {
          if (wallet.id == transaction.walletId) {
            walletName = wallet.name;
            break;
          }
        }

        final isExpense = transaction.type == TransactionType.expense;
        final isIncome = transaction.type == TransactionType.income;
        final sign = isExpense ? '-' : '+';
        final amountColor = isExpense
            ? AppColors.errorColor
            : AppColors.primaryColor;

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: amountColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: amountColor,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note?.trim().isNotEmpty ?? false
                          ? transaction.note!
                          : isExpense
                          ? 'مصروف'
                          : 'دخل',
                      style: AppTextStyle.style14W600.copyWith(
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      walletName == null
                          ? DateFormat(
                              'd MMM - h:mm a',
                              'ar',
                            ).format(transaction.date)
                          : '$walletName • ${DateFormat('d MMM - h:mm a', 'ar').format(transaction.date)}',
                      style: AppTextStyle.style12Bold.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${appSettings.formatAmount(transaction.amount)}',
                style: AppTextStyle.style14W600.copyWith(color: amountColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AllocationProgressList extends StatelessWidget {
  const _AllocationProgressList({
    required this.plannedExpenses,
    required this.transactions,
  });

  final List<PlannedExpense> plannedExpenses;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsStore(sharedPreferences: getIt());
    if (plannedExpenses.isEmpty) {
      return const _EmptyStateBox(
        message: 'ابدأ بإعداد الميزانية الشهرية لتظهر متابعة المخصصات هنا.',
      );
    }

    final spentByCategory = <String, double>{};
    for (final transaction in transactions.where(
      (item) => item.type == TransactionType.expense,
    )) {
      final categoryId = transaction.primaryCategoryId;
      if (categoryId == null) continue;
      spentByCategory[categoryId] =
          (spentByCategory[categoryId] ?? 0) + transaction.amount;
    }

    final cards = plannedExpenses.map((expense) {
      final spent = spentByCategory[expense.categoryId] ?? 0.0;
      return _AllocationProgressData(
        title: expense.name,
        planned: expense.budgetedAmount,
        spent: spent,
      );
    }).toList()..sort((a, b) => b.spent.compareTo(a.spent));

    final visibleCards = cards.take(math.min(4, cards.length)).toList();

    return Column(
      children: visibleCards.map((item) {
        final progress = item.planned <= 0
            ? 0.0
            : (item.spent / item.planned).clamp(0.0, 1.0);

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTextStyle.style14W600.copyWith(
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                  ),
                  Text(
                    '${appSettings.formatAmount(item.spent)} / ${appSettings.formatAmount(item.planned)}',
                    style: AppTextStyle.style12Bold.copyWith(
                      color: AppColors.textGreyColor,
                    ),
                  ),
                ],
              ),
              10.verticalSpace,
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: LinearProgressIndicator(
                  minHeight: 10.h,
                  value: progress,
                  backgroundColor: Colors.black.withAlpha(8),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AllocationProgressData {
  const _AllocationProgressData({
    required this.title,
    required this.planned,
    required this.spent,
  });

  final String title;
  final double planned;
  final double spent;
}

class _EmptyStateBox extends StatelessWidget {
  const _EmptyStateBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.black.withAlpha(10)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyle.style12Bold.copyWith(
          color: AppColors.textGreyColor,
        ),
      ),
    );
  }
}
