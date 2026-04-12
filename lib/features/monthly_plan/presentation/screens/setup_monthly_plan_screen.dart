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
                orElse: () => const Wallet(
                  id: 's',
                  name: 'التوفير',
                  balance: 0,
                ),
              );
              final hasalat = wallets
                  .where((w) => w.type == WalletType.jar)
                  .toList();

              final totalIncome = plan.totalPlannedIncome;
              final hasalatTotal = hasalat.fold(
                0.0,
                (s, w) => s + (w.monthlyAmount ?? 0),
              );
              final savingsTotal = savingsWallet.monthlyAmount ?? 0.0;
              final totalAllocated =
                  plan.totalBudgetedExpense +
                  plan.totalPlannedDebts +
                  hasalatTotal +
                  savingsTotal;
              final unallocated = totalIncome - totalAllocated;

              final startDate = planState.currentMonth;
              final endDate = startDate.add(const Duration(days: 30));
              final dateRangeStr =
                  'فترة الخطة: ${startDate.day} ${_getMonthArabicName(startDate.month)} إلى ${endDate.day} ${_getMonthArabicName(endDate.month)}';

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: 'اختر يوم بداية الخطة',
                        );
                        if (picked != null && context.mounted) {
                          await context
                              .read<MonthlyPlanCubit>()
                              .loadPlanForMonth(
                                picked,
                              );
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
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
                            8.horizontalSpace,
                            Icon(
                              Icons.edit,
                              size: 14.r,
                              color: Colors.grey,
                            ),
                          ],
                        ),
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

                    _buildDetailedSection(
                      context: context,
                      title: 'مصادر الدخل',
                      isEmpty: plan.incomes.isEmpty,
                      emptyText: 'لم يتم إضافة مصادر دخل',
                      onAdd: () =>
                          _showAddEditIncomeDialog(context, false, plan),
                      icon: Icons.payments_outlined,
                      accentColor: Colors.green,
                      buttonLabel: 'إضافة دخل',
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

                    _buildDetailedSection(
                      context: context,
                      title: 'المخصصات',
                      isEmpty: plan.expenses.isEmpty,
                      emptyText: 'لم يتم إضافة مخصصات',
                      onAdd: () => _showAddEditAllocationDialog(context, plan),
                      icon: Icons.pie_chart_outline_rounded,
                      accentColor: const Color(0xFF2563EB),
                      buttonLabel: 'إضافة مخصص',
                      child: Column(
                        children: plan.expenses
                            .map(
                              (e) => _buildAllocationItem(
                                context,
                                e,
                                plan,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    _buildDetailedSection(
                      context: context,
                      title: 'الحصالات',
                      isEmpty: hasalat.isEmpty,
                      emptyText: 'لم يتم إضافة حصالات',
                      onAdd: () => _showAddEditLinkedWalletDialog(context),
                      icon: Icons.savings_outlined,
                      accentColor: const Color(0xFF0F766E),
                      buttonLabel: 'إضافة حصالة',
                      child: Column(
                        children: hasalat
                            .map((w) => _buildWalletItem(context, w))
                            .toList(),
                      ),
                    ),
                    24.verticalSpace,

                    _buildDetailedSection(
                      context: context,
                      title: 'الديون والمتكررة',
                      isEmpty: plan.debts.isEmpty,
                      emptyText: 'لم يتم إضافة ديون',
                      onAdd: () => _showAddEditDebtDialog(context, plan),
                      icon: Icons.receipt_long_outlined,
                      accentColor: const Color(0xFFD97706),
                      buttonLabel: 'إضافة دين',
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
        colorValue,
      ) {
        final updated = savingsWallet.copyWith(
          monthlyAmount: amount,
          recurrenceType: recurrenceType,
          selectedDays: selectedDays,
          executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
        );
        context.read<WalletCubit>().updateWallet(updated);
      },
      initialName: 'محفظة التوفير',
      initialAmount: savingsWallet.monthlyAmount,
      nameEnabled: false,
      showEndOfMonth: false,
      initialRecurrenceType: savingsWallet.recurrenceType,
      initialSelectedDays: savingsWallet.selectedDays,
    );
  }

  Widget _buildCyclePlanningCard({
    required String dateRangeStr,
    required double unallocated,
  }) {
    final isBalanced = unallocated >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.indigo.withAlpha(18),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 18.r,
                  color: Colors.indigo,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  'الدورة الحالية للخطة',
                  style: AppTextStyle.style14Bold,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Text(
            dateRangeStr,
            style: AppTextStyle.style12Bold.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          8.verticalSpace,
          Text(
            'ابدأ من هنا: سجّل الدخل، ثم وزّعه على المخصصات والحصالات والديون والتوفير قبل تأكيد بداية الخطة.',
            style: AppTextStyle.style12W500.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          12.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: (isBalanced ? Colors.green : Colors.red).withAlpha(14),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  isBalanced ? Icons.check_circle_outline : Icons.error_outline,
                  size: 18.r,
                  color: isBalanced ? Colors.green : Colors.red,
                ),
                8.horizontalSpace,
                Expanded(
                  child: Text(
                    isBalanced
                        ? 'الخطة متوازنة حاليًا ويمكنك الاستمرار في توزيع البنود.'
                        : 'الخطة ما زالت بالسالب. قلل الالتزامات أو زد الدخل قبل التأكيد.',
                    style: AppTextStyle.style12W500.copyWith(
                      color: isBalanced
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetModelInfoCard({
    required double allocationsTotal,
    required double hasalatTotal,
    required double debtsTotal,
    required double savingsTotal,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryColor.withAlpha(20),
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 18.r,
                  color: AppColors.primaryColor,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  'هيكل فكرة الميزانية',
                  style: AppTextStyle.style14Bold,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Text(
            'الدخل هنا لا يذهب مباشرة للمصروف فقط. هو يتوزع على المخصصات والحصالات والديون والتوفير، وبعدها تتابع التنفيذ من المحافظ الفعلية.',
            style: AppTextStyle.style12W500.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          12.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildInfoPill(
                'المخصصات',
                allocationsTotal,
                const Color(0xFF2563EB),
              ),
              _buildInfoPill('الحصالات', hasalatTotal, const Color(0xFF0F766E)),
              _buildInfoPill('الديون', debtsTotal, const Color(0xFFD97706)),
              _buildInfoPill('التوفير', savingsTotal, const Color(0xFFFF7A00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          8.horizontalSpace,
          Text(
            '$label ${value.toStringAsFixed(2)}',
            style: AppTextStyle.style12Bold.copyWith(color: color),
          ),
        ],
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

  Widget _buildDetailedSection({
    required BuildContext context,
    required String title,
    required bool isEmpty,
    required String emptyText,
    required VoidCallback onAdd,
    required Widget child,
    String? subtitle,
    IconData? icon,
    Color accentColor = AppColors.secondaryTextColor,
    String buttonLabel = 'إضافة',
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: accentColor.withAlpha(18),
                  child: Icon(icon, size: 18.r, color: accentColor),
                ),
                12.horizontalSpace,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.style18Bold.copyWith(
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      4.verticalSpace,
                      Text(
                        subtitle,
                        style: AppTextStyle.style12W500.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              12.horizontalSpace,
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  buttonLabel,
                  style: AppTextStyle.style12W500.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: Size(96.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          if (isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            child,
        ],
      ),
    );
  }

  // Widget _buildSection({
  //   required BuildContext context,
  //   required String title,
  //   required bool isEmpty,
  //   required String emptyText,
  //   required VoidCallback onAdd,
  //   required Widget child,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             title,
  //             style: AppTextStyle.style18Bold.copyWith(
  //               color: AppColors.secondaryTextColor,
  //             ),
  //           ),
  //           ElevatedButton.icon(
  //             onPressed: onAdd,
  //             icon: const Icon(Icons.add, size: 16, color: Colors.white),
  //             label: Text(
  //               'إضافة',
  //               style: AppTextStyle.style12W500.copyWith(color: Colors.white),
  //             ),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.primaryColor,
  //               minimumSize: Size(80.w, 36.h),
  //               padding: EdgeInsets.symmetric(horizontal: 12.w),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8.r),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       12.verticalSpace,
  //       if (isEmpty)
  //         Container(
  //           width: double.infinity,
  //           padding: EdgeInsets.symmetric(vertical: 30.h),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12.r),
  //             border: Border.all(color: Colors.black12),
  //           ),
  //           child: Center(
  //             child: Text(
  //               emptyText,
  //               style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
  //             ),
  //           ),
  //         )
  //       else
  //         child,
  //     ],
  //   );
  // }

  Widget _buildIncomeItem(
    BuildContext context,
    PlannedIncome item,
    MonthlyPlan plan,
  ) {
    final isDefault = item.id == 'default_salary';
    final recurrenceStr = _getRecurrenceText(
      item.recurrenceType,
      item.selectedDays,
      item.executionDay,
    );

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
                      ? '$recurrenceStr - ${item.executionType.label}'
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
                  item.endOfMonthAction.label,
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
    final recurrenceStr = _getRecurrenceText(
      w.recurrenceType,
      w.selectedDays,
      w.executionDay ?? 1,
    );

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
            child: const Icon(Icons.savings_outlined, color: Colors.teal),
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
                  'تمويل من الخطة - $recurrenceStr',
                  style: AppTextStyle.style12W500.copyWith(color: Colors.teal),
                ),
                2.verticalSpace,
                Text(
                  _getExecutionTypeName(w.executionType),
                  style: AppTextStyle.style12W500.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            w.plannedMonthlyFunding.toStringAsFixed(2),
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
    final recurrenceStr = _getRecurrenceText(
      item.recurrenceType,
      item.selectedDays,
      item.executionDay,
    );

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
                  '$recurrenceStr - ${item.executionType.label}',
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
              onPressed: () {
                final newExpenses = plan.expenses
                    .where((e) => e.id != itemToEdit.id)
                    .toList();
                context.read<MonthlyPlanCubit>().updatePlan(
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
        colorValue,
      ) {
        final txCubit = context.read<TransactionCubit>();

        var category = txCubit.state.allCategories
            .where((c) => c.name == name && c.type == TransactionType.expense)
            .toList()
            .fold<TransactionCategory?>(
              null,
              (prev, element) => prev ?? element,
            );

        if (category == null) {
          category = TransactionCategory(
            id: const Uuid().v4(),
            name: name,
            type: TransactionType.expense,
            colorValue: colorValue,
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
            walletId: null,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
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
            walletId: null,
            recurrenceType: recurrenceType,
            selectedDays: selectedDays,
          );
          context.read<MonthlyPlanCubit>().updatePlan(
            plan.copyWith(expenses: [...plan.expenses, newExpense]),
          );
        }
      },
      showIncomeSource: true,
      showEndOfMonth: true,
      showExpenseWallet: false,
      initialName: itemToEdit?.name,
      initialAmount: itemToEdit?.budgetedAmount,
      initialSourceId: itemToEdit?.sourceId,
      initialEndAction: itemToEdit?.endOfMonthAction,
      initialRecurrenceType: itemToEdit?.recurrenceType,
      initialSelectedDays: itemToEdit?.selectedDays,
    );
  }

  void _showAddEditIncomeDialog(
    BuildContext context,
    bool isDefault,
    MonthlyPlan plan, {
    PlannedIncome? itemToEdit,
  }) {
    final isEdit = itemToEdit != null;

    _showGenericDialog(
      context,
      isEdit ? 'تعديل مصدر دخل' : 'إضافة مصدر دخل',
      (isEdit && !isDefault)
          ? IconButton(
              icon: const Icon(CupertinoIcons.delete_simple, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                final newIncomes = plan.incomes
                    .where((i) => i.id != itemToEdit.id)
                    .toList();
                context.read<MonthlyPlanCubit>().updatePlan(
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
        colorValue,
      ) {
        final txCubit = context.read<TransactionCubit>();
        var category = txCubit.state.allCategories
            .where((c) => c.name == name && c.type == TransactionType.income)
            .toList()
            .fold<TransactionCategory?>(
              null,
              (prev, element) => prev ?? element,
            );

        if (category == null) {
          category = TransactionCategory(
            id: const Uuid().v4(),
            name: name,
            type: TransactionType.income,
            colorValue: colorValue,
          );
          txCubit.addCategory(category);
        }

        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            amount: amount,
            executionType: type,
            recurrenceType: recurrenceType,
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
            selectedDays: selectedDays,
            isFixed: isFixed,
            targetWalletId: null,
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
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
            selectedDays: selectedDays,
            isFixed: isFixed,
            targetWalletId: null,
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
      initialSelectedDays:
          (itemToEdit?.selectedDays != null &&
              itemToEdit!.selectedDays.isNotEmpty)
          ? itemToEdit.selectedDays
          : (itemToEdit?.executionDay != null
                ? [itemToEdit!.executionDay]
                : null),
      initialIsFixed: itemToEdit?.isFixed,
      nameEnabled: !isDefault,
      showFixedOption: true,
      showDepositWallet: false,
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
              onPressed: () {
                context.read<WalletCubit>().deleteWallet(walletToEdit.id);
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
        colorValue,
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
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
            selectedDays: selectedDays,
          );
          context.read<WalletCubit>().updateWallet(updated);
        } else {
          final newWallet = Wallet(
            id: const Uuid().v4(),
            name: name,
            balance: 0.0,
            type: WalletType.jar,
            monthlyAmount: amount,
            executionType: executionTypeEnum,
            sourceWalletId: sourceId,
            recurrenceType: recurrenceType,
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
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
      initialSelectedDays:
          (walletToEdit?.selectedDays != null &&
              walletToEdit!.selectedDays.isNotEmpty)
          ? walletToEdit.selectedDays
          : (walletToEdit?.executionDay != null
                ? [walletToEdit!.executionDay!]
                : null),
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
              onPressed: () {
                final newDebts = plan.debts
                    .where((d) => d.id != itemToEdit.id)
                    .toList();
                context.read<MonthlyPlanCubit>().updatePlan(
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
        colorValue,
      ) {
        if (isEdit) {
          final updated = itemToEdit.copyWith(
            name: name,
            amount: amount,
            executionType: type,
            sourceId: sourceId,
            recurrenceType: recurrenceType,
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
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
            executionDay: selectedDays.isNotEmpty ? selectedDays.first : 1,
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
      initialSelectedDays:
          (itemToEdit?.selectedDays != null &&
              itemToEdit!.selectedDays.isNotEmpty)
          ? itemToEdit.selectedDays
          : (itemToEdit?.executionDay != null
                ? [itemToEdit!.executionDay]
                : null),
    );
  }

  void _showQuickAddWallet(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'إضافة محفظة سريعة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'اسم المحفظة (مثال: كاش، بنك)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final w = Wallet(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  balance: 0,
                  type: WalletType.real,
                );
                context.read<WalletCubit>().addWallet(w);
                Navigator.pop(c);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
      int colorValue,
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

    var selectedRecurrence = initialRecurrenceType ?? RecurrenceType.none;
    var currentSelectedDays = initialSelectedDays ?? [];
    var selectedType = initialType ?? PlanExecutionType.manual;
    var selectedEndAction =
        initialEndAction ?? EndOfMonthAction.transferToSavings;
    var selectedSourceId = initialSourceId;
    var selectedTargetWalletId = initialTargetWalletId;
    var isFixed = initialIsFixed ?? true;
    Color selectedColor = Colors.blue;
    if (initialName != null) {
      selectedColor = Colors.blue;
    }
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
                    10.verticalSpace,

                    Text(
                      'اختار لون التصنيف',
                      style: AppTextStyle.style12W600,
                    ),

                    10.verticalSpace,

                    Wrap(
                      spacing: 8,
                      children:
                          [
                            Colors.blue,
                            Colors.green,
                            Colors.red,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.amber,
                            Colors.indigo,
                          ].map((color) {
                            final isSelected =
                                selectedColor.value == color.value;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedColor = color),
                              child: Container(
                                width: 30.w,
                                height: 30.w,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                          value: selectedRecurrence,
                          selectedDays: currentSelectedDays,
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
                      BlocBuilder<WalletCubit, WalletState>(
                        builder: (context, wState) {
                          final wallets = (wState is WalletLoaded)
                              ? wState.wallets.toList()
                              : <Wallet>[];

                          if (selectedTargetWalletId == null &&
                              wallets.isNotEmpty) {
                            selectedTargetWalletId = wallets.first.id;
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedTargetWalletId,
                                  decoration: InputDecoration(
                                    labelText:
                                        'محفظة الإيداع (أين سيتم حفظ الأموال؟)',
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
                                  onChanged: (v) => setState(
                                    () => selectedTargetWalletId = v,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.add_box,
                                  color: AppColors.primaryColor,
                                  size: 36.r,
                                ),
                                onPressed: () => _showQuickAddWallet(context),
                              ),
                            ],
                          );
                        },
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
                      BlocBuilder<WalletCubit, WalletState>(
                        builder: (context, wState) {
                          final wallets = (wState is WalletLoaded)
                              ? wState.wallets.toList()
                              : <Wallet>[];

                          final isTargetValid =
                              selectedTargetWalletId == null ||
                              wallets.any(
                                (w) => w.id == selectedTargetWalletId,
                              );
                          if (!isTargetValid) selectedTargetWalletId = null;

                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: selectedTargetWalletId,
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
                                    ...wallets.map(
                                      (w) => DropdownMenuItem<String?>(
                                        value: w.id,
                                        child: Text(w.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(
                                    () => selectedTargetWalletId = v,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.add_box,
                                  color: AppColors.primaryColor,
                                  size: 36.r,
                                ),
                                onPressed: () => _showQuickAddWallet(context),
                              ),
                            ],
                          );
                        },
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
                            selectedColor.value,
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

  String _getRecurrenceText(
    RecurrenceType type,
    List<int> days,
    int defaultDay,
  ) {
    switch (type) {
      case RecurrenceType.none:
        return 'مرة واحدة (يوم $defaultDay)';
      case RecurrenceType.daily:
        return 'كل يوم';
      case RecurrenceType.weekdays:
        return 'أيام العمل';
      case RecurrenceType.weekends:
        return 'الويك إند';
      case RecurrenceType.weekly:
        final d = days.map(_getWeekDayName).join('، ');
        return 'أسبوعياً${d.isNotEmpty ? ' ($d)' : ''}';
      case RecurrenceType.biWeekly:
        final d = days.map(_getWeekDayName).join('، ');
        return 'كل أسبوعين${d.isNotEmpty ? ' ($d)' : ''}';
      case RecurrenceType.everyFourWeeks:
        final d = days.map(_getWeekDayName).join('، ');
        return 'كل 4 أسابيع${d.isNotEmpty ? ' ($d)' : ''}';
      case RecurrenceType.monthly:
        return 'شهرياً (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.everyTwoMonths:
        return 'كل شهرين (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.everyThreeMonths:
        return 'كل 3 أشهر (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.everyFourMonths:
        return 'كل 4 أشهر (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.everySixMonths:
        return 'كل 6 أشهر (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.endOfMonth:
        return 'آخر الشهر';
      case RecurrenceType.yearly:
        if (days.length == 2) {
          return 'سنوياً (يوم ${days[1]} / ${days[0]})';
        }
        return 'سنوياً';
    }
  }

  String _getWeekDayName(int day) {
    switch (day) {
      case 1:
        return 'الإثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }
}
