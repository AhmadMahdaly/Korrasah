import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        title: 'المعاملات المتكررة',
        isLeading: true,
        heightBar: 80.h,
      ),
      body: BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
        builder: (context, state) {
          if (state.plan == null) {
            return const Center(child: Text('لا توجد خطة مفعلة حالياً'));
          }

          final plan = state.plan!;

          return Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomesList(plan),
                    _buildExpensesList(plan),
                    _buildDebtsList(plan),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryColor,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: AppTextStyle.style14Bold,
        tabs: const [
          Tab(text: 'الدخل'),
          Tab(text: 'المصروفات'),
          Tab(text: 'الالتزامات'),
        ],
      ),
    );
  }

  Widget _buildIncomesList(MonthlyPlan plan) {
    if (plan.incomes.isEmpty) return _buildEmptyState('لا يوجد دخل متكرر مضاف');
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: plan.incomes.length,
      itemBuilder: (context, index) {
        final item = plan.incomes[index];
        return _buildRecurringCard(
          title: item.name,
          amount: item.amount,
          isIncome: true,
          recurrence: _getRecurrenceText(
            item.recurrenceType,
            item.selectedDays,
            item.executionDay,
          ),
          executionType: item.executionType.label,
          onDelete: () => _deleteIncome(item.id),
        );
      },
    );
  }

  Widget _buildExpensesList(MonthlyPlan plan) {
    if (plan.expenses.isEmpty)
      return _buildEmptyState('لا توجد مصروفات متكررة');
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: plan.expenses.length,
      itemBuilder: (context, index) {
        final item = plan.expenses[index];
        return _buildRecurringCard(
          title: item.name,
          amount: item.budgetedAmount,
          isIncome: false,
          recurrence: _getRecurrenceText(
            item.recurrenceType,
            item.selectedDays,
            1,
          ),
          executionType: 'مخصص شهري',
          onDelete: () => _deleteExpense(item.id),
        );
      },
    );
  }

  Widget _buildDebtsList(MonthlyPlan plan) {
    if (plan.debts.isEmpty) return _buildEmptyState('لا توجد التزامات متكررة');
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: plan.debts.length,
      itemBuilder: (context, index) {
        final item = plan.debts[index];
        return _buildRecurringCard(
          title: item.name,
          amount: item.amount,
          isIncome: false,
          recurrence: _getRecurrenceText(
            item.recurrenceType,
            item.selectedDays,
            item.executionDay,
          ),
          executionType: item.executionType.label,
          onDelete: () => _deleteDebt(item.id),
        );
      },
    );
  }

  Widget _buildRecurringCard({
    required String title,
    required double amount,
    required bool isIncome,
    required String recurrence,
    required String executionType,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20.r,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.style16Bold),
                4.verticalSpace,
                Text(
                  '$recurrence • $executionType',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)}',
                style: AppTextStyle.style16Bold.copyWith(
                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.trash,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _showDeleteConfirm(onDelete),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_repeat, size: 64.r, color: Colors.grey.shade300),
          16.verticalSpace,
          Text(
            msg,
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  void _deleteIncome(String id) {
    final cubit = context.read<MonthlyPlanCubit>();
    final plan = cubit.state.plan!;
    final newList = plan.incomes.where((i) => i.id != id).toList();
    cubit.updatePlan(plan.copyWith(incomes: newList));
  }

  void _deleteExpense(String id) {
    final cubit = context.read<MonthlyPlanCubit>();
    final plan = cubit.state.plan!;
    final newList = plan.expenses.where((e) => e.id != id).toList();
    cubit.updatePlan(plan.copyWith(expenses: newList));
  }

  void _deleteDebt(String id) {
    final cubit = context.read<MonthlyPlanCubit>();
    final plan = cubit.state.plan!;
    final newList = plan.debts.where((d) => d.id != id).toList();
    cubit.updatePlan(plan.copyWith(debts: newList));
  }

  void _showDeleteConfirm(VoidCallback onConfirm) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('حذف المعاملة'),
        content: const Text(
          'هل أنت متأكد من رغبتك في إيقاف هذه المعاملة المتكررة؟',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
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
      case RecurrenceType.monthly:
        return 'شهرياً (يوم ${days.isNotEmpty ? days.first : defaultDay})';
      case RecurrenceType.endOfMonth:
        return 'آخر الشهر';
      case RecurrenceType.yearly:
        return 'سنوياً';
      default:
        return 'شهرياً';
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
