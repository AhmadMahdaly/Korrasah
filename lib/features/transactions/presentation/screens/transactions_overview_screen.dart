import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/services/app_settings_store.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

class TransactionsOverviewScreen extends StatelessWidget {
  const TransactionsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsStore(sharedPreferences: getIt());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const PageHeader(
        isLeading: true,
        heightBar: 86,
        title: 'المعاملات',
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, planState) {
          final month = planState.currentMonth;
          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, transactionState) {
              return BlocBuilder<WalletCubit, WalletState>(
                builder: (context, walletState) {
                  final wallets = walletState is WalletLoaded
                      ? walletState.wallets
                      : <Wallet>[];
                  final monthTransactions = transactionState.allTransactions
                      .where(
                        (item) =>
                            item.date.year == month.year &&
                            item.date.month == month.month,
                      )
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final totalIncome = monthTransactions
                      .where((item) => item.type == TransactionType.income)
                      .fold<double>(0, (sum, item) => sum + item.amount);
                  final totalExpenses = monthTransactions
                      .where((item) => item.type == TransactionType.expense)
                      .fold<double>(0, (sum, item) => sum + item.amount);

                  final grouped = <String, List<Transaction>>{};
                  for (final transaction in monthTransactions) {
                    final key = DateFormat('yyyy-MM-dd').format(transaction.date);
                    grouped.putIfAbsent(key, () => <Transaction>[]);
                    grouped[key]!.add(transaction);
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TransactionSummaryCard(
                              label: 'إجمالي الدخل',
                              value: appSettings.formatAmount(totalIncome),
                              valueColor: AppColors.primaryColor,
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: _TransactionSummaryCard(
                              label: 'إجمالي المصروف',
                              value: appSettings.formatAmount(totalExpenses),
                              valueColor: AppColors.errorColor,
                            ),
                          ),
                        ],
                      ),
                      18.verticalSpace,
                      if (grouped.isEmpty)
                        const _TransactionsEmptyState()
                      else
                        ...grouped.entries.map((entry) {
                          final date = DateTime.parse(entry.key);
                          final dayTransactions = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 18.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Text(
                                    DateFormat(
                                      'EEEE، d MMMM',
                                      'ar',
                                    ).format(date),
                                    style: AppTextStyle.style12Bold.copyWith(
                                      color: AppColors.textGreyColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22.r),
                                    border: Border.all(
                                      color: Colors.black.withAlpha(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: dayTransactions.map((transaction) {
                                      String? walletName;
                                      for (final wallet in wallets) {
                                        if (wallet.id == transaction.walletId) {
                                          walletName = wallet.name;
                                          break;
                                        }
                                      }

                                      return _TransactionRow(
                                        transaction: transaction,
                                        walletName: walletName,
                                        amountLabel: appSettings.formatAmount(
                                          transaction.amount,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TransactionSummaryCard extends StatelessWidget {
  const _TransactionSummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.style12Bold.copyWith(
              color: AppColors.textGreyColor,
            ),
          ),
          8.verticalSpace,
          Text(
            value,
            style: AppTextStyle.style18W700.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.walletName,
    required this.amountLabel,
  });

  final Transaction transaction;
  final String? walletName;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isExpense
        ? AppColors.errorColor
        : AppColors.primaryColor;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(8)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: amountColor.withAlpha(18),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: amountColor,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note?.trim().isNotEmpty == true
                      ? transaction.note!
                      : isExpense
                          ? 'مصروف'
                          : transaction.type == TransactionType.transfer
                              ? 'تحويل'
                              : 'دخل',
                  style: AppTextStyle.style14W600.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                ),
                4.verticalSpace,
                Text(
                  walletName == null
                      ? DateFormat('HH:mm', 'ar').format(transaction.date)
                      : '$walletName • ${DateFormat('HH:mm', 'ar').format(transaction.date)}',
                  style: AppTextStyle.style12W400.copyWith(
                    color: AppColors.textGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}$amountLabel',
            style: AppTextStyle.style14W700.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}

class _TransactionsEmptyState extends StatelessWidget {
  const _TransactionsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 42.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56.r,
            color: AppColors.textGreyColor,
          ),
          14.verticalSpace,
          Text(
            'لا توجد معاملات في هذا الشهر',
            style: AppTextStyle.style16W700.copyWith(
              color: AppColors.primaryTextColor,
            ),
          ),
          8.verticalSpace,
          Text(
            'ابدأ بإضافة أول معاملة لتظهر هنا.',
            textAlign: TextAlign.center,
            style: AppTextStyle.style12W400.copyWith(
              color: AppColors.textGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}
