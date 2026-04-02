import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/shared_widgets/show_custom_snackbar.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(
        isLeading: true,
        title: 'الإشعارات',
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, planState) {
          return BlocBuilder<WalletCubit, WalletState>(
            builder: (context, walletState) {
              return BlocBuilder<TransactionCubit, TransactionState>(
                builder: (context, state) {
                  final now = DateTime.now();
                  final plan = planState.plan;
                  final wallets = walletState is WalletLoaded
                      ? walletState.wallets
                      : <Wallet>[];

                  final pending = state.pendingTransactions.where((category) {
                    var isManual = false;
                    var isAuto = false;
                    var isConfirm = false;
                    var recurrence = RecurrenceType.none;
                    var selectedDays = <int>[];

                    var found = false;

                    if (plan != null && !found) {
                      final items = plan.incomes
                          .where((i) => i.name == category.name)
                          .toList();
                      if (items.isNotEmpty) {
                        final item = items.first;
                        recurrence = item.recurrenceType;
                        selectedDays = item.selectedDays;
                        if (item.executionType.name == 'auto') isAuto = true;
                        if (item.executionType.name == 'manual')
                          isManual = true;
                        if (item.executionType.name == 'confirm')
                          isConfirm = true;
                        found = true;
                      }
                    }

                    if (plan != null && !found) {
                      final items = plan.debts
                          .where((d) => d.name == category.name)
                          .toList();
                      if (items.isNotEmpty) {
                        final item = items.first;
                        recurrence = item.recurrenceType;
                        selectedDays = item.selectedDays;
                        if (item.executionType.name == 'auto') isAuto = true;
                        if (item.executionType.name == 'manual')
                          isManual = true;
                        if (item.executionType.name == 'confirm')
                          isConfirm = true;
                        found = true;
                      }
                    }

                    if (!found) {
                      final items = wallets
                          .where((w) => w.id == category.id)
                          .toList();
                      if (items.isNotEmpty &&
                          items.first.type.name == 'sideLinked') {
                        final item = items.first;
                        recurrence = item.recurrenceType;
                        selectedDays = item.selectedDays;
                        if (item.executionType.name == 'auto') isAuto = true;
                        if (item.executionType.name == 'manual')
                          isManual = true;
                        if (item.executionType.name == 'confirm')
                          isConfirm = true;
                        found = true;
                      }
                    }

                    if (plan != null && !found) {
                      final items = plan.expenses
                          .where((e) => e.categoryId == category.id)
                          .toList();
                      if (items.isNotEmpty) {
                        final item = items.first;
                        recurrence = item.recurrenceType;
                        selectedDays = item.selectedDays;

                        isConfirm = recurrence != RecurrenceType.none;
                        found = true;
                      }
                    }

                    if (!found) {
                      if (category.autoDeduct) {
                        isAuto = true;
                      } else if (category.recurrenceType !=
                          RecurrenceType.none) {
                        isConfirm = true;
                      } else {
                        isManual = true;
                      }
                      recurrence = category.recurrenceType;
                      if (category.dayOfMonth != null) {
                        selectedDays.add(category.dayOfMonth!);
                      }
                      if (category.daysOfWeek != null) {
                        selectedDays.addAll(category.daysOfWeek!);
                      }
                    }

                    if (isManual || isAuto || !isConfirm) return false;
                    if (recurrence == RecurrenceType.none) return false;

                    switch (recurrence) {
                      case RecurrenceType.daily:
                        return true;
                      case RecurrenceType.weekdays:
                        return now.weekday != 5 && now.weekday != 6;
                      case RecurrenceType.weekends:
                        return now.weekday == 5 || now.weekday == 6;
                      case RecurrenceType.weekly:
                      case RecurrenceType.biWeekly:
                      case RecurrenceType.everyFourWeeks:
                        if (selectedDays.isNotEmpty &&
                            !selectedDays.contains(now.weekday)) {
                          return false;
                        }
                        return true;
                      case RecurrenceType.monthly:
                      case RecurrenceType.everyTwoMonths:
                      case RecurrenceType.everyThreeMonths:
                      case RecurrenceType.everyFourMonths:
                      case RecurrenceType.everySixMonths:
                        if (selectedDays.isNotEmpty &&
                            !selectedDays.contains(now.day)) {
                          return false;
                        }
                        return true;
                      case RecurrenceType.endOfMonth:
                        final tomorrow = now.add(const Duration(days: 1));
                        return tomorrow.month != now.month;
                      case RecurrenceType.yearly:
                        if (selectedDays.length >= 2) {
                          if (now.month != selectedDays[0] ||
                              now.day != selectedDays[1]) {
                            return false;
                          }
                        }
                        return true;
                      case RecurrenceType.none:
                        return false;
                      default:
                        return false;
                    }
                  }).toList();

                  if (pending.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80.r,
                            color: AppColors.textGreyColor.withAlpha(100),
                          ),
                          16.verticalSpace,
                          Text(
                            'مفيش أي إشعارات أو عمليات معلقة',
                            style: AppTextStyle.style16W500.copyWith(
                              color: AppColors.textGreyColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemCount: pending.length,
                    separatorBuilder: (_, _) => 12.verticalSpace,
                    itemBuilder: (context, index) {
                      final category = pending[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: AppColors.orangeColor.withAlpha(100),
                          ),
                        ),
                        color: AppColors.orangeColor.withAlpha(15),
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: category.color,
                                    radius: 20.r,
                                    child: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  12.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تأكيد تسجيل "${category.name}"',
                                          style: AppTextStyle.style14W600,
                                        ),
                                        4.verticalSpace,
                                        Text(
                                          'المبلغ المتوقع: ${category.fixedAmount?.truncate() ?? 0} ج.م',
                                          style: AppTextStyle.style12W400
                                              .copyWith(
                                                color:
                                                    AppColors.primaryTextColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              16.verticalSpace,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      context
                                          .read<TransactionCubit>()
                                          .dismissPendingTransaction(category);
                                      showCustomSnackBar(
                                        context,
                                        message: 'تم التجاهل',
                                        backgroundColor:
                                            AppColors.textGreyColor,
                                      );
                                    },
                                    child: Text(
                                      'تجاهل اليوم',
                                      style: TextStyle(
                                        color: AppColors.textGreyColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                  8.horizontalSpace,
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      context
                                          .read<TransactionCubit>()
                                          .approvePendingTransaction(category);
                                      showCustomSnackBar(
                                        context,
                                        message:
                                            'تم تسجيل "${category.name}" بنجاح',
                                      );
                                    },
                                    child: const Text(
                                      'تأكيد وتسجيل',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
