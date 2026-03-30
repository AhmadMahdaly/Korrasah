import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/core/constants.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart' show PageHeader;
import 'package:opration/core/shared_widgets/show_custom_snackbar.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/transactions/presentation/screens/widgets/add_category_dialog.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().checkScheduledTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final finalCategoryId = _selectedSubCategoryId ?? _selectedMainCategoryId;

      if (finalCategoryId == null) {
        showCustomSnackBar(
          context,
          msgColor: AppColors.scaffoldBackgroundLightColor,
          message: _selectedType == TransactionType.expense
              ? 'متنساش تختار المخصص اللي صرفت منه'
              : 'متنساش تختار مصدر الدخل',
          backgroundColor: AppColors.orangeColor,
        );
        return;
      }

      if (_selectedWalletId == null) {
        showCustomSnackBar(
          context,
          msgColor: AppColors.scaffoldBackgroundLightColor,
          message: 'الرجاء اختيار المحفظة أولاً.',
        );
        return;
      }

      final amount = double.parse(_amountController.text);

      final transaction = Transaction(
        id: getIt<Uuid>().v4(),
        amount: amount,
        categoryId: finalCategoryId,
        date: _selectedDate,
        note: _noteController.text.isNotEmpty ? _noteController.text : '',
        type: _selectedType,
        walletId: _selectedWalletId!,
      );

      // حفظ المعاملة
      context.read<TransactionCubit>().addTransaction(transaction);

      // تحديث المحفظة
      context.read<WalletCubit>().updateWalletBalance(
        _selectedWalletId!,
        _selectedType == TransactionType.income ? amount : -amount,
      );

      playTimerSound();

      _amountController.clear();
      _noteController.clear();
      setState(() {
        _selectedMainCategoryId = null;
        _selectedSubCategoryId = null;
        _selectedDate = DateTime.now();
      });

      showCustomSnackBar(
        context,
        msgColor: Colors.white,
        message: 'تم التسجيل بنجاح',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  double _calculateRemaining(
    TransactionCategory category,
    MonthlyPlan? plan,
    List<Transaction> allTxs,
    List<TransactionCategory> allCategories,
  ) {
    if (plan == null) return 0.0;

    final now = DateTime.now();
    final subCategories = allCategories
        .where((c) => c.parentId == category.id)
        .toList();
    final relevantIds = [category.id, ...subCategories.map((c) => c.id)];

    var budgeted = 0.0;
    var spent = 0.0;

    if (_selectedType == TransactionType.expense) {
      for (final id in relevantIds) {
        budgeted += plan.getExpenseForCategory(id)?.budgetedAmount ?? 0.0;
      }
      spent = allTxs
          .where(
            (t) =>
                relevantIds.contains(t.categoryId) &&
                t.type == TransactionType.expense &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
    } else {
      final relevantNames = [
        category.name,
        ...subCategories.map((c) => c.name),
      ];
      for (final name in relevantNames) {
        budgeted += plan.incomes
            .where((i) => i.name == name)
            .fold(0.0, (sum, i) => sum + i.amount);
      }
      spent = allTxs
          .where(
            (t) =>
                relevantIds.contains(t.categoryId) &&
                t.type == TransactionType.income &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    return budgeted - spent;
  }

  void _addNewSubCategoryForSelectedMain() {
    if (_selectedMainCategoryId == null) return;

    final allCategories = context.read<TransactionCubit>().state.allCategories;
    final mainCategory = allCategories.firstWhere(
      (c) => c.id == _selectedMainCategoryId,
    );

    final dummySubCategory = TransactionCategory(
      id: '',
      name: '',
      colorValue: mainCategory.colorValue,
      type: mainCategory.type,
      parentId: mainCategory.id,
    );

    showModalBottomSheet<TransactionCategory>(
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      context: context,
      builder: (_) => AddCategoryWidget(
        type: mainCategory.type,
        categoryToEdit: dummySubCategory,
      ),
    ).then((result) {
      if (result != null) {
        final newSubCategory = result.copyWith(id: const Uuid().v4());
        context.read<TransactionCubit>().addCategory(newSubCategory);
        setState(() {
          _selectedSubCategoryId = newSubCategory.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PageHeader(
        isLeading: false,
        heightBar: 80.h,
        title: 'تسجيل معاملة',
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, txState) {
          final allCategories = txState.allCategories;
          final mainCategories = allCategories
              .where((c) => c.type == _selectedType && c.parentId == null)
              .toList();
          final subCategories = _selectedMainCategoryId != null
              ? allCategories
                    .where((c) => c.parentId == _selectedMainCategoryId)
                    .toList()
              : <TransactionCategory>[];

          return BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
            builder: (context, planState) {
              return BlocBuilder<WalletCubit, WalletState>(
                builder: (context, walletState) {
                  final wallets = (walletState is WalletLoaded)
                      ? walletState.wallets
                      : <Wallet>[];

                  if (_selectedWalletId == null && wallets.isNotEmpty) {
                    final mainWallet = wallets.firstWhere(
                      (w) => w.isMain,
                      orElse: () => wallets.first,
                    );
                    _selectedWalletId = mainWallet.id;
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16.r),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. نوع المعاملة (Toggle)
                          Text(
                            'نوع المعاملة',
                            style: AppTextStyles.style14Bold,
                          ),
                          10.verticalSpace,
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeToggle(
                                  title: 'دخل',
                                  icon: Icons.call_received,
                                  isSelected:
                                      _selectedType == TransactionType.income,
                                  activeColor: AppColors.successColor,
                                  onTap: () => setState(() {
                                    _selectedType = TransactionType.income;
                                    _selectedMainCategoryId = null;
                                    _selectedSubCategoryId = null;
                                  }),
                                ),
                              ),
                              12.horizontalSpace,
                              Expanded(
                                child: _buildTypeToggle(
                                  title: 'مصروف',
                                  icon: Icons.call_made,
                                  isSelected:
                                      _selectedType == TransactionType.expense,
                                  activeColor: AppColors.errorColor,
                                  onTap: () => setState(() {
                                    _selectedType = TransactionType.expense;
                                    _selectedMainCategoryId = null;
                                    _selectedSubCategoryId = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          24.verticalSpace,

                          // 2. المبلغ
                          Text('المبلغ', style: AppTextStyles.style14Bold),
                          8.verticalSpace,
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    left: 16.w,
                                    top: 14.h,
                                  ),
                                  child: Text(
                                    'ج.م',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'سجل المبلغ'
                                  : null,
                            ),
                          ),
                          24.verticalSpace,

                          // 3. المحفظة
                          Text('المحفظة', style: AppTextStyles.style14Bold),
                          8.verticalSpace,
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWalletId,
                            decoration: _dropdownDecoration(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                            items: wallets
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(
                                      '${w.name} (${w.balance.truncate()} ج.م)',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedWalletId = v),
                            validator: (v) => v == null ? 'اختر المحفظة' : null,
                          ),
                          24.verticalSpace,

                          // 4. المخصص (Main Category)
                          Text('المخصص *', style: AppTextStyles.style14Bold),
                          8.verticalSpace,
                          DropdownButtonFormField<String>(
                            initialValue: _selectedMainCategoryId,
                            decoration: _dropdownDecoration(),
                            hint: const Text('اختر المخصص'),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                            items: mainCategories.map((cat) {
                              final remaining = _calculateRemaining(
                                cat,
                                planState.plan,
                                txState.allTransactions,
                                allCategories,
                              );
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(
                                  '${cat.name} (متبقي: ${remaining.truncate()})',
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() {
                              _selectedMainCategoryId = v;
                              _selectedSubCategoryId =
                                  null; // تصفير الفئة الفرعية
                            }),
                            validator: (v) => v == null ? 'اختر المخصص' : null,
                          ),
                          24.verticalSpace,

                          // 5. الفئة (Sub Category)
                          if (_selectedMainCategoryId != null) ...[
                            Text('الفئة *', style: AppTextStyles.style14Bold),
                            8.verticalSpace,
                            if (subCategories.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'لا توجد فئات لهذا المخصص',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    12.verticalSpace,
                                    OutlinedButton.icon(
                                      onPressed:
                                          _addNewSubCategoryForSelectedMain,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('إضافة فئة'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryColor,
                                        side: BorderSide(
                                          color: AppColors.primaryColor
                                              .withAlpha(50),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  ...subCategories.map(
                                    (cat) => ChoiceChip(
                                      label: Text(cat.name),
                                      selected:
                                          _selectedSubCategoryId == cat.id,
                                      onSelected: (selected) => setState(
                                        () => _selectedSubCategoryId = selected
                                            ? cat.id
                                            : null,
                                      ),
                                      selectedColor: cat.color.withAlpha(40),
                                      labelStyle: TextStyle(
                                        color: _selectedSubCategoryId == cat.id
                                            ? cat.color
                                            : Colors.black87,
                                        fontWeight:
                                            _selectedSubCategoryId == cat.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        side: BorderSide(
                                          color:
                                              _selectedSubCategoryId == cat.id
                                              ? cat.color
                                              : Colors.black12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ActionChip(
                                    label: const Text('إضافة +'),
                                    onPressed:
                                        _addNewSubCategoryForSelectedMain,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      side: const BorderSide(
                                        color: Colors.black12,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            24.verticalSpace,
                          ],

                          // 6. ملاحظات
                          Text(
                            'ملاحظات (اختياري)',
                            style: AppTextStyles.style14Bold,
                          ),
                          8.verticalSpace,
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: TextFormField(
                              controller: _noteController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'أضف ملاحظة...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16.r),
                              ),
                            ),
                          ),
                          32.verticalSpace,

                          // زر الحفظ
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A86B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: const Text(
                                'حفظ المعاملة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      ),
    );
  }

  // تصميم الـ Dropdown ليكون متطابق مع الصورة
  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    );
  }

  // تصميم أزرار الدخل والمصروف
  Widget _buildTypeToggle({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey,
              size: 28.r,
            ),
            8.verticalSpace,
            Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void playTimerSound() {
  final player = AudioPlayer();
  const sound = appSound;
  player.play(AssetSource(sound));
}
