import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/constants.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/router/app_routes.dart';
import 'package:opration/core/shared_widgets/custom_primary_button.dart';
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
  @override
  void initState() {
    super.initState();

    context.read<TransactionCubit>().checkScheduledTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: PageHeader(
          isLeading: false,
          heightBar: 145.h,

          bottom: Container(
            height: 50.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.white,
                width: 0.5.w,
              ),
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: TabBar(
              indicatorPadding: EdgeInsets.all(3.r),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadius),
                color: AppColors.white,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.white,
              labelStyle: AppTextStyle.style14W600.copyWith(
                fontFamily: kPrimaryFont,
              ),
              unselectedLabelStyle: AppTextStyle.style14W600.copyWith(
                fontFamily: kPrimaryFont,
              ),
              tabs: const [
                Tab(text: 'مصاريف'),
                Tab(text: 'فلوس داخلة'),
              ],
            ),
          ),

          actions: [
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                final pendingCount = state.pendingTransactions.length;

                return SizedBox(
                  width: 45.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.white,
                          size: 24.r,
                        ),
                        onPressed: () {
                          context.pushNamed(
                            AppRoutes.notificationsScreen,
                          );
                        },
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: IgnorePointer(
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
                        ),
                    ],
                  ),
                );
              },
            ),
            16.horizontalSpace,
          ],
        ),
        body: const TabBarView(
          children: [
            _TransactionForm(type: TransactionType.expense),

            _TransactionForm(type: TransactionType.income),
          ],
        ),
      ),
    );
  }
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm({required this.type});
  final TransactionType type;

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;

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
          msgColor: AppColors.white,
          message: widget.type == TransactionType.expense
              ? 'متنساش تختار المخصص اللي صرفت منه'
              : 'متنساش تختار مصدر الدخل',
          backgroundColor: AppColors.orangeColor,
        );
        return;
      }

      if (_selectedWalletId == null) {
        showCustomSnackBar(
          context,
          msgColor: AppColors.white,
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
        type: widget.type,
        walletId: _selectedWalletId!,
      );

      context.read<TransactionCubit>().addTransaction(transaction);

      context.read<WalletCubit>().updateWalletBalance(
        _selectedWalletId!,
        widget.type == TransactionType.income ? amount : -amount,
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

    if (widget.type == TransactionType.expense) {
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
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, txState) {
        final allCategories = txState.allCategories;
        final mainCategories = allCategories
            .where((c) => c.type == widget.type && c.parentId == null)
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
                          .where(
                            (w) =>
                                w.type != WalletType.savings &&
                                w.type != WalletType.mainBudget,
                          )
                          .toList()
                    : <Wallet>[];

                if (_selectedWalletId == null && wallets.isNotEmpty) {
                  _selectedWalletId = wallets.first.id;
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المبلغ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.verticalSpace,
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
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
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(left: 16.w, top: 14.h),
                                child: Text(
                                  'ج.م',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'سجل المبلغ'
                                : null,
                          ),
                        ),
                        24.verticalSpace,

                        Text(
                          'المحفظة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

                        Text(
                          widget.type == TransactionType.expense
                              ? 'المخصص *'
                              : 'مصدر الدخل *',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.verticalSpace,
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMainCategoryId,
                          decoration: _dropdownDecoration(),
                          hint: Text(
                            widget.type == TransactionType.expense
                                ? 'اختر المخصص'
                                : 'اختر المصدر',
                          ),
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
                                widget.type == TransactionType.expense
                                    ? '${cat.name} (متبقي: ${remaining.truncate()})'
                                    : cat.name,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() {
                            _selectedMainCategoryId = v;
                            _selectedSubCategoryId = null;
                          }),
                          validator: (v) => v == null ? 'مطلوب' : null,
                        ),
                        24.verticalSpace,

                        if (_selectedMainCategoryId != null) ...[
                          Text(
                            'الفئة *',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                    'لا توجد فئات هنا',
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
                                        color: AppColors.primaryColor.withAlpha(
                                          50,
                                        ),
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
                                    selected: _selectedSubCategoryId == cat.id,
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
                                      borderRadius: BorderRadius.circular(8.r),
                                      side: BorderSide(
                                        color: _selectedSubCategoryId == cat.id
                                            ? cat.color
                                            : Colors.black12,
                                      ),
                                    ),
                                  ),
                                ),
                                ActionChip(
                                  label: const Text('إضافة +'),
                                  onPressed: _addNewSubCategoryForSelectedMain,
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

                        Text(
                          'ملاحظات (اختياري)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
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
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                        32.verticalSpace,

                        CustomPrimaryButton(
                          onPressed: _submit,
                          text: 'حفظ المعاملة',
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
  }

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
}

void playTimerSound() {
  final player = AudioPlayer();
  const sound = appSound;
  player.play(AssetSource(sound));
}
