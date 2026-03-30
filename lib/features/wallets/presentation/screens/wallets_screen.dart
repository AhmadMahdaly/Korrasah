// ignore_for_file: no_default_cases

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/custom_dropdown_button.dart';
import 'package:opration/core/shared_widgets/custom_primary_textfield.dart';
import 'package:opration/core/shared_widgets/page_header.dart' show PageHeader;
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
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
      appBar: PageHeader(
        isLeading: false,
        heightBar: 80.h,
        title: 'المحافظ',
        actions: [
          TextButton.icon(
            onPressed: () {
              final state = context.read<WalletCubit>().state;
              if (state is WalletLoaded) {
                _showTransferDialog(context, state.wallets);
              }
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.black87),
            label: const Text('تحويل', style: TextStyle(color: Colors.black87)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          10.horizontalSpace,
          ElevatedButton.icon(
            onPressed: () => _showAddEditSideWalletDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          16.horizontalSpace,
        ],
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
            final mainWallet = walletState.wallets.firstWhere(
              (w) => w.type == WalletType.mainBudget,
              orElse: () => walletState.wallets.first,
            );
            final savingsWallet = walletState.wallets.firstWhere(
              (w) => w.type == WalletType.savings,
              orElse: () => walletState.wallets.first,
            );
            final sideWallets = walletState.wallets
                .where(
                  (w) =>
                      w.type == WalletType.sideIndependent ||
                      w.type == WalletType.sideLinked,
                )
                .toList();

            return BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, txState) {
                final now = DateTime.now();
                var currentMonthIncome = 0.0;
                var currentMonthExpense = 0.0;

                for (final tx in txState.allTransactions) {
                  if (tx.walletId == mainWallet.id &&
                      tx.date.year == now.year &&
                      tx.date.month == now.month) {
                    if (tx.type == TransactionType.income) {
                      currentMonthIncome += tx.amount;
                    } else if (tx.type == TransactionType.expense) {
                      currentMonthExpense += tx.amount;
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      _buildMainCard(
                        wallet: mainWallet,
                        color: const Color(0xFF00A86B),
                        income: currentMonthIncome,
                        expense: currentMonthExpense,
                      ),
                      16.verticalSpace,

                      _buildSavingsCard(savingsWallet, const Color(0xFFFF7A00)),
                      24.verticalSpace,

                      _buildSideWalletsSection(context, sideWallets),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMainCard({
    required Wallet wallet,
    required Color color,
    required double income,
    required double expense,
  }) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(backgroundColor: Colors.white, radius: 24.r),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    wallet.name,
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                  Text(
                    '${wallet.balance.toStringAsFixed(2)} ريال',
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
              _buildMiniStat(
                'المصروفات (هذا الشهر)',
                expense.toStringAsFixed(2),
              ),
              _buildMiniStat('الدخل (هذا الشهر)', income.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildSavingsCard(Wallet wallet, Color color) {
  return Container(
    padding: EdgeInsets.all(20.r),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16.r),
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
              'ريال',
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
              'محفظة ثابتة لا تحذف',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
        CircleAvatar(backgroundColor: Colors.white, radius: 24.r),
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

Widget _buildSideWalletsSection(
  BuildContext context,
  List<Wallet> sideWallets,
) {
  if (sideWallets.isEmpty) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet, size: 60.r, color: Colors.black12),
          16.verticalSpace,
          Text(
            'لا توجد محافظ جانبية',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          8.verticalSpace,
          Text(
            'أضف محفظة جديدة لبدء التتبع',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
          24.verticalSpace,
          ElevatedButton(
            onPressed: () => _showAddEditSideWalletDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              'إضافة محفظة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'المحافظ الجانبية',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      16.verticalSpace,
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sideWallets.length,
        separatorBuilder: (context, index) => 10.verticalSpace,
        itemBuilder: (context, index) {
          final wallet = sideWallets[index];
          final isLinked = wallet.type == WalletType.sideLinked;

          return InkWell(
            onTap: () => _showAddEditSideWalletDialog(context, wallet: wallet),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade500,
                    radius: 22.r,
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
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
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                isLinked ? 'مرتبطة بالميزانية' : 'مستقلة',
                                style: TextStyle(
                                  color: isLinked
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        6.verticalSpace,
                        if (isLinked)
                          Text(
                            '${wallet.monthlyAmount?.truncate() ?? 0} شهرياً • يوم ${wallet.executionDay ?? '-'} • ${_getExecutionTypeName(wallet.executionType)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10.sp,
                            ),
                          )
                        else
                          Text(
                            'محفظة فرعية غير مرتبطة',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
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
          );
        },
      ),
    ],
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
    _sourceWalletId = w?.sourceWalletId;
  }

  @override
  Widget build(BuildContext context) {
    final wallets = (context.read<WalletCubit>().state as WalletLoaded).wallets;

    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Form(
        key: _formKey,
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
            16.verticalSpace,

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
                    child: Text('تأكيد'),
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
                items: wallets
                    .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _sourceWalletId = v),
              ),
            ],

            20.verticalSpace,
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newWallet = Wallet(
        id: widget.wallet?.id ?? const Uuid().v4(),
        name: _nameController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
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

      if (widget.wallet != null) {
        context.read<WalletCubit>().updateWallet(newWallet);
      } else {
        context.read<WalletCubit>().addWallet(newWallet);
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
              style: AppTextStyles.style18W700.copyWith(
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
                                style: AppTextStyles.style12W500,
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
                      style: AppTextStyles.style12W500.copyWith(
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
                      style: AppTextStyles.style14W500,
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
                                  style: AppTextStyles.style14W500,
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
                        style: AppTextStyles.style14W500.copyWith(
                          color: AppColors.scaffoldBackgroundLightColor,
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
