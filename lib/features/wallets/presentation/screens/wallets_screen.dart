import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/shared_widgets/custom_dropdown_button.dart';
import 'package:opration/core/shared_widgets/custom_primary_button.dart';
import 'package:opration/core/shared_widgets/custom_primary_textfield.dart';
import 'package:opration/core/shared_widgets/page_header.dart' show PageHeader;
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/core/theme/themes.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';
import 'package:uuid/uuid.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SpeedDial(
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 4.h,
        spaceBetweenChildren: 4.h,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.history),
            label: 'سجل التحويلات',
            onTap: () {
              context.pushNamed(AppRoutes.transferHistoryScreen);
            },
          ),
          SpeedDialChild(
            child: const Icon(
              Icons.swap_horiz,
            ),
            label: 'تحويل',
            onTap: () {
              final state = context.read<WalletCubit>().state;
              if (state is WalletLoaded) {
                _showTransferDialog(context, state.wallets);
              }
            },
          ),

          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'إضافة حساب',
            onTap: () => _showAddEditSideWalletDialog(context),
          ),
        ],
      ),
      appBar: PageHeader(
        isLeading: false,
        heightBar: 80.h,
        title: 'المحافظ والترحيل',
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, walletState) {
          if (walletState is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (walletState is WalletError) {
            return Center(child: Text('خطأ: ${walletState.message}'));
          }

          if (walletState is WalletLoaded) {
            final savingsWallet = walletState.wallets.firstWhere(
              (w) => w.type == WalletType.savings,
              orElse: () => walletState.wallets.first,
            );

            final actualWallets = walletState.wallets
                .where(
                  (w) =>
                      w.type != WalletType.savings &&
                      w.type != WalletType.mainBudget,
                )
                .toList();

            return BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
              builder: (context, planState) {
                final currentMonth = planState.currentMonth;

                return BlocBuilder<TransactionCubit, TransactionState>(
                  builder: (context, txState) {
                    var monthlyTotalIncome = 0.0;
                    var monthlyTotalExpense = 0.0;

                    for (final tx in txState.allTransactions) {
                      if (tx.date.year == currentMonth.year &&
                          tx.date.month == currentMonth.month) {
                        if (tx.type == TransactionType.income) {
                          monthlyTotalIncome += tx.amount;
                        } else if (tx.type == TransactionType.expense) {
                          monthlyTotalExpense += tx.amount;
                        }
                      }
                    }

                    final netRemaining =
                        monthlyTotalIncome - monthlyTotalExpense;

                    return Column(
                      children: [
                        _buildMonthSelector(context, currentMonth),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBudgetAggregatorCard(
                                  context: context,
                                  income: monthlyTotalIncome,
                                  expense: monthlyTotalExpense,
                                  netRemaining: netRemaining,
                                  savingsWalletId: savingsWallet.id,
                                  actualWallets: actualWallets,
                                  monthName: _getMonthArabicName(
                                    currentMonth.month,
                                  ),
                                ),
                                16.verticalSpace,

                                _buildSavingsCard(
                                  savingsWallet,
                                  const Color(0xFFFF7A00),
                                ),
                                24.verticalSpace,

                                _buildActualWalletsSection(
                                  context,
                                  actualWallets,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }
          return const SizedBox();
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
          bottom: BorderSide(color: Colors.black.withAlpha(15)),
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

  Widget _buildBudgetAggregatorCard({
    required BuildContext context,
    required double income,
    required double expense,
    required double netRemaining,
    required String savingsWalletId,
    required List<Wallet> actualWallets,
    required String monthName,
  }) {
    final isPositive = netRemaining >= 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: appGradient(),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(66),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 32.r),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'محصلة شهر $monthName (الفائض)',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${netRemaining.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          20.verticalSpace,
          const Divider(color: Colors.white30),
          10.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('المصروف الفعلي', expense.toStringAsFixed(2)),
              _buildMiniStat('الدخل الفعلي', income.toStringAsFixed(2)),
            ],
          ),
          16.verticalSpace,

          if (netRemaining > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showRolloverToSavingsDialog(
                    context,
                    netRemaining,
                    savingsWalletId,
                    actualWallets,
                  );
                },
                icon: const Icon(
                  Icons.move_to_inbox,
                  color: AppColors.secondaryTextColor,
                  size: 18,
                ),
                label: Text(
                  'ترحيل الفائض للادخار',
                  style: AppTextStyle.style12Bold.copyWith(
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(Wallet wallet, Color color) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.balance.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ج.م',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                wallet.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'المحفظة الآمنة',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withAlpha(55),
            radius: 24.r,
            child: const Icon(Icons.savings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActualWalletsSection(
    BuildContext context,
    List<Wallet> actualWallets,
  ) {
    if (actualWallets.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            children: [
              Icon(
                Icons.account_balance,
                size: 60.r,
                color: Colors.grey.shade300,
              ),
              16.verticalSpace,
              Text(
                'لا توجد حسابات أو محافظ مسجلة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحسابات الفعلية (كاش، بنك، إلكتروني)',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        16.verticalSpace,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actualWallets.length,
          separatorBuilder: (context, index) => 10.verticalSpace,
          itemBuilder: (context, index) {
            final wallet = actualWallets[index];
            final isLinked = wallet.type == WalletType.sideLinked;

            return Dismissible(
              key: Key(wallet.id),
              direction: DismissDirection.endToStart,

              background: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.delete_sweep,
                  color: Colors.white,
                  size: 30.r,
                ),
              ),

              confirmDismiss: (direction) async {
                return showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      title: const Text(
                        'تأكيد الحذف',
                        style: TextStyle(color: Colors.red),
                      ),
                      content: Text(
                        'هل أنت متأكد من حذف محفظة "${wallet.name}"؟\nسيتم إزالة رصيدها من الميزانية وحذف معاملاتها.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'تراجع',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'حذف',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },

              onDismissed: (direction) {
                context.read<WalletCubit>().deleteWallet(wallet.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف المحفظة "${wallet.name}" بنجاح'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },

              child: InkWell(
                onTap: () =>
                    _showAddEditSideWalletDialog(context, wallet: wallet),
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryTextColor.withAlpha(
                          55,
                        ),
                        radius: 22.r,
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primaryTextColor,
                          size: 22.r,
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  wallet.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                8.horizontalSpace,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLinked
                                        ? AppColors.primaryTextColor.withAlpha(
                                            55,
                                          )
                                        : AppColors.primaryTextColor.withAlpha(
                                            20,
                                          ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    isLinked ? 'مرتبطة بالخطة' : 'مستقلة',
                                    style: TextStyle(
                                      color: isLinked
                                          ? AppColors.secondaryTextColor
                                          : AppColors.primaryTextColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            wallet.balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          Text(
                            'ج.م',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                      12.horizontalSpace,
                      Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: 14.r,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showRolloverToSavingsDialog(
    BuildContext context,
    double netRemaining,
    String savingsWalletId,
    List<Wallet> actualWallets,
  ) {
    String? selectedSourceWalletId;
    final amountCtrl = TextEditingController(
      text: netRemaining.toStringAsFixed(2),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ترحيل الفائض لمحفظة التوفير',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  8.verticalSpace,
                  Text(
                    'يوجد لديك فائض ميزانية هذا الشهر بقيمة ${netRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  20.verticalSpace,

                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المراد ترحيله',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  16.verticalSpace,

                  DropdownButtonFormField<String>(
                    initialValue: selectedSourceWalletId,
                    decoration: const InputDecoration(
                      labelText: 'سحب الفائض من أي حساب فعلي؟',
                      border: OutlineInputBorder(),
                    ),
                    items: actualWallets
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text('${w.name} (${w.balance})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedSourceWalletId = v),
                  ),
                  24.verticalSpace,

                  CustomPrimaryButton(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                      if (selectedSourceWalletId != null && amount > 0) {
                        context.read<WalletCubit>().transferBalance(
                          selectedSourceWalletId!,
                          savingsWalletId,
                          amount,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم ترحيل الفائض بنجاح! 🚀',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color(0xFF00A86B),
                          ),
                        );
                      }
                    },
                    text: 'تأكيد الترحيل',
                  ),
                  10.verticalSpace,
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditSideWalletDialog(BuildContext context, {Wallet? wallet}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddSideWalletForm(wallet: wallet),
      ),
    );
  }
}

class _AddSideWalletForm extends StatefulWidget {
  const _AddSideWalletForm({this.wallet});
  final Wallet? wallet;

  @override
  State<_AddSideWalletForm> createState() => _AddSideWalletFormState();
}

class _AddSideWalletFormState extends State<_AddSideWalletForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _monthlyAmountController;
  late TextEditingController _executionDayController;

  bool _isLinkedToBudget = false;
  ExecutionType _executionType = ExecutionType.confirm;
  String? _sourceWalletId;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameController = TextEditingController(text: w?.name);
    _balanceController = TextEditingController(
      text: w?.balance.toString() ?? '',
    );

    _isLinkedToBudget = w?.type == WalletType.sideLinked;
    _monthlyAmountController = TextEditingController(
      text: w?.monthlyAmount?.toString() ?? '',
    );
    _executionDayController = TextEditingController(
      text: w?.executionDay?.toString() ?? '',
    );

    _executionType = w?.executionType ?? ExecutionType.confirm;
    if (_executionType == ExecutionType.none) {
      _executionType = ExecutionType.confirm;
    }

    _sourceWalletId = w?.sourceWalletId;
  }

  @override
  Widget build(BuildContext context) {
    final planState = context.read<MonthlyPlanCubit>().state;
    final incomes = planState.plan?.incomes ?? [];

    if (_sourceWalletId != null &&
        !incomes.any((i) => i.id == _sourceWalletId)) {
      _sourceWalletId = null;
    }

    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.wallet == null ? 'إضافة محفظة جانبية' : 'تعديل محفظة',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              20.verticalSpace,

              CustomPrimaryTextfield(
                controller: _nameController,
                text: 'اسم المحفظة',
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              10.verticalSpace,
              CustomPrimaryTextfield(
                controller: _balanceController,
                text: 'الرصيد الافتتاحي',
                keyboardType: TextInputType.number,
              ),
              10.verticalSpace,

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('مستقلة'),
                      value: false,
                      groupValue: _isLinkedToBudget,
                      onChanged: (val) =>
                          setState(() => _isLinkedToBudget = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('مرتبطة'),
                      value: true,
                      groupValue: _isLinkedToBudget,
                      onChanged: (val) =>
                          setState(() => _isLinkedToBudget = val!),
                    ),
                  ),
                ],
              ),

              if (_isLinkedToBudget) ...[
                CustomPrimaryTextfield(
                  controller: _monthlyAmountController,
                  text: 'المبلغ الشهري',
                  keyboardType: TextInputType.number,
                ),
                10.verticalSpace,
                CustomPrimaryTextfield(
                  controller: _executionDayController,
                  text: 'يوم التنفيذ (1-31)',
                  keyboardType: TextInputType.number,
                ),
                10.verticalSpace,

                DropdownButtonFormField<ExecutionType>(
                  initialValue: _executionType,
                  decoration: const InputDecoration(labelText: 'نوع التنفيذ'),
                  items: const [
                    DropdownMenuItem(
                      value: ExecutionType.confirm,
                      child: Text('يحتاج تأكيد'),
                    ),
                    DropdownMenuItem(
                      value: ExecutionType.auto,
                      child: Text('تلقائي'),
                    ),
                    DropdownMenuItem(
                      value: ExecutionType.manual,
                      child: Text('يدوي'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _executionType = v!),
                ),
                10.verticalSpace,

                DropdownButtonFormField<String>(
                  initialValue: _sourceWalletId,
                  decoration: const InputDecoration(labelText: 'مصدر الفلوس'),
                  items: incomes
                      .map(
                        (i) =>
                            DropdownMenuItem(value: i.id, child: Text(i.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _sourceWalletId = v),
                ),
              ],

              20.verticalSpace,
              CustomPrimaryButton(
                onPressed: _save,
                text: 'حفظ',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final isNewWallet = widget.wallet == null;

      final newWalletId = widget.wallet?.id ?? const Uuid().v4();
      final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;

      final newWallet = Wallet(
        id: newWalletId,
        name: _nameController.text,
        balance: initialBalance,
        isMain: false,
        type: _isLinkedToBudget
            ? WalletType.sideLinked
            : WalletType.sideIndependent,
        monthlyAmount: _isLinkedToBudget
            ? double.tryParse(_monthlyAmountController.text)
            : null,
        executionDay: _isLinkedToBudget
            ? int.tryParse(_executionDayController.text)
            : null,
        executionType: _isLinkedToBudget ? _executionType : ExecutionType.none,
        sourceWalletId: _isLinkedToBudget ? _sourceWalletId : null,
      );

      if (isNewWallet) {
        context.read<WalletCubit>().addWallet(newWallet);

        if (initialBalance > 0) {
          final initialTransaction = Transaction(
            id: const Uuid().v4(),
            walletId: newWalletId,
            amount: initialBalance,
            type: TransactionType.income,
            date: DateTime.now(),

            note: 'رصيد إضافة المحفظة',
            categoryId: 'initial_balance_category_id',
          );

          context.read<TransactionCubit>().addTransaction(initialTransaction);
        }
      } else {
        context.read<WalletCubit>().updateWallet(newWallet);
      }

      Navigator.pop(context);
    }
  }
}

void _showTransferDialog(BuildContext context, List<Wallet> wallets) {
  String? fromWalletId;
  String? toWalletId;
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet<void>(
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          children: [
            Text(
              'نقل مبلغ بين المحافظ',
              style: AppTextStyle.style18W700.copyWith(
                color: AppColors.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            20.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12.h,
                  children: [
                    CustomDropdownButtonFormField<String>(
                      hintText: 'من محفظة',
                      items: wallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                '${w.name} (${w.balance.truncate()} ج.م)',
                                style: AppTextStyle.style12W500,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => fromWalletId = v,
                      validator: (v) => v == null ? 'حدد المحفظة' : null,
                    ),

                    CustomDropdownButtonFormField<String>(
                      hintText: 'إلى محفظة',
                      items: wallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => toWalletId = v,
                      validator: (v) => v == null ? 'حدد المحفظة' : null,
                    ),

                    CustomPrimaryTextfield(
                      controller: amountController,
                      text: 'المبلغ المراد تحويله',
                      style: AppTextStyle.style12W500.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || double.tryParse(v) == null) {
                          return 'أدخل رقم صحيح';
                        }
                        if (double.parse(v) <= 0) {
                          return 'المبلغ يجب أن يكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            30.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'إلغاء',
                      style: AppTextStyle.style14W500,
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          if (fromWalletId == toWalletId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'لا يمكن التحويل لنفس المحفظة!',
                                  style: AppTextStyle.style14W500,
                                ),
                              ),
                            );
                            return;
                          }

                          context.read<WalletCubit>().transferBalance(
                            fromWalletId!,
                            toWalletId!,
                            double.parse(amountController.text),
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        'تأكيد التحويل',
                        style: AppTextStyle.style14W500.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
