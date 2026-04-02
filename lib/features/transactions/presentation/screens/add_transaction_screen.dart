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

    final planCubit = context.read<MonthlyPlanCubit>();
    if (planCubit.state.plan == null) {
      planCubit.loadPlanForMonth(DateTime.now());
    }
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
              border: Border.all(color: AppColors.white, width: 0.5.w),
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
                        onPressed: () =>
                            context.pushNamed(AppRoutes.notificationsScreen),
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

  bool _isWalletTarget = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWalletId == null) {
        showCustomSnackBar(
          context,
          msgColor: AppColors.white,
          message: 'الرجاء اختيار المحفظة أولاً.',
        );
        return;
      }

      String? finalCategoryId;

      if (_isWalletTarget) {
        finalCategoryId = _selectedSubCategoryId ?? _selectedWalletId;
      } else {
        finalCategoryId = _selectedSubCategoryId ?? _selectedMainCategoryId;
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
      }

      final amount = double.parse(_amountController.text);

      final transaction = Transaction(
        id: getIt<Uuid>().v4(),
        amount: amount,
        allocationId: finalCategoryId,
        date: _selectedDate,
        note: _noteController.text.isNotEmpty ? _noteController.text : '',
        type: widget.type,
        walletId: _selectedWalletId,
      );

      await context.read<TransactionCubit>().addTransaction(transaction);

      if (mounted) {
        await context.read<WalletCubit>().loadWallets();
        await context.read<MonthlyPlanCubit>().refreshBudgetSummary();
      }

      playTimerSound();

      _amountController.clear();
      _noteController.clear();
      setState(() {
        _selectedMainCategoryId = null;
        _selectedSubCategoryId = null;
        _selectedDate = DateTime.now();
      });

      if (mounted) {
        showCustomSnackBar(
          context,
          msgColor: Colors.white,
          message: 'تم التسجيل بنجاح',
          backgroundColor: AppColors.successColor,
        );
      }
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
                relevantIds.contains(t.allocationId) &&
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
                relevantIds.contains(t.allocationId) &&
                t.type == TransactionType.income &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    return budgeted - spent;
  }

  void _addNewSubCategoryForSelectedMain() {
    final parentId = _isWalletTarget
        ? _selectedWalletId
        : _selectedMainCategoryId;

    if (parentId == null) return;

    final allCategories = context.read<TransactionCubit>().state.allCategories;

    final parentCategory = allCategories.firstWhere(
      (c) => c.id == parentId,
      orElse: () => TransactionCategory(
        id: parentId,
        name: 'فئة جديدة',
        colorValue: Colors.blueGrey.value,
        type: widget.type,
      ),
    );

    _showAddSubCategoryBottomSheet(
      context,
      parentCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, txState) {
        final allCategories = txState.allCategories;

        return BlocBuilder<MonthlyPlanCubit, MonthlyPlanState>(
          builder: (context, planState) {
            final plan = planState.plan;

            var categoryDropdownItems = <DropdownMenuItem<String>>[];

            if (!_isWalletTarget && plan != null) {
              if (widget.type == TransactionType.expense) {
                categoryDropdownItems = plan.expenses.map((exp) {
                  final category = allCategories.firstWhere(
                    (c) => c.id == exp.categoryId,
                    orElse: () => TransactionCategory(
                      id: exp.categoryId,
                      name: exp.name,
                      colorValue: Colors.grey.value,
                      type: TransactionType.expense,
                    ),
                  );

                  final remaining = _calculateRemaining(
                    category,
                    plan,
                    txState.allTransactions,
                    allCategories,
                  );

                  return DropdownMenuItem(
                    value: category.id,
                    child: Text('${exp.name} (متبقي: ${remaining.truncate()})'),
                  );
                }).toList();
              } else {
                categoryDropdownItems = plan.incomes
                    .map((inc) {
                      final category = allCategories.firstWhere(
                        (c) =>
                            c.name == inc.name &&
                            c.type == TransactionType.income,
                        orElse: () => TransactionCategory(
                          id: '',
                          name: inc.name,
                          colorValue: Colors.grey.value,
                          type: TransactionType.income,
                        ),
                      );

                      return DropdownMenuItem<String>(
                        value: category.id.isNotEmpty ? category.id : null,
                        child: Text(inc.name),
                      );
                    })
                    .where((item) => item.value != null)
                    .toList();
              }

              if (_selectedMainCategoryId != null &&
                  !categoryDropdownItems.any(
                    (item) => item.value == _selectedMainCategoryId,
                  )) {
                _selectedMainCategoryId = null;
              }
            }

            final parentIdForSub = _isWalletTarget
                ? _selectedWalletId
                : _selectedMainCategoryId;

            final subCategories = parentIdForSub != null
                ? allCategories
                      .where((c) => c.parentId == parentIdForSub)
                      .toList()
                : <TransactionCategory>[];

            return BlocBuilder<WalletCubit, WalletState>(
              builder: (context, walletState) {
                var wallets = (walletState is WalletLoaded)
                    ? walletState.wallets.toList()
                    : <Wallet>[];

                if (!_isWalletTarget) {
                  wallets = wallets
                      .where((w) => w.type == WalletType.sideLinked)
                      .toList();
                } else {
                  wallets = wallets
                      .where(
                        (w) =>
                            w.type == WalletType.sideIndependent ||
                            w.type == WalletType.savings,
                      )
                      .toList();
                }

                if (_selectedWalletId != null &&
                    !wallets.any((w) => w.id == _selectedWalletId)) {
                  _selectedWalletId = null;
                }

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
                          'نوع المعاملة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(
                                  widget.type == TransactionType.expense
                                      ? 'من مخصص'
                                      : 'مصدر خطة',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                value: false,
                                groupValue: _isWalletTarget,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() {
                                  _isWalletTarget = val!;
                                  _selectedWalletId = null;
                                  _selectedMainCategoryId = null;
                                  _selectedSubCategoryId = null;
                                }),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(
                                  'محفظة مباشرة',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                value: true,
                                groupValue: _isWalletTarget,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() {
                                  _isWalletTarget = val!;
                                  _selectedWalletId = null;
                                  _selectedMainCategoryId = null;
                                  _selectedSubCategoryId = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        24.verticalSpace,

                        Text(
                          widget.type == TransactionType.expense
                              ? 'المحفظة (الدفع من) *'
                              : 'المحفظة (الإيداع في) *',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.verticalSpace,
                        DropdownButtonFormField<String>(
                          value: _selectedWalletId,
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
                          onChanged: (v) => setState(() {
                            _selectedWalletId = v;
                            if (_isWalletTarget) {
                              _selectedSubCategoryId = null;
                            }
                          }),
                          validator: (v) => v == null ? 'اختر المحفظة' : null,
                        ),
                        24.verticalSpace,

                        if (!_isWalletTarget) ...[
                          Text(
                            widget.type == TransactionType.expense
                                ? 'المخصص الأساسي *'
                                : 'مصدر الدخل الأساسي *',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          8.verticalSpace,
                          DropdownButtonFormField<String>(
                            value: _selectedMainCategoryId,
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
                            items: categoryDropdownItems,
                            onChanged: (v) => setState(() {
                              _selectedMainCategoryId = v;
                              _selectedSubCategoryId = null;
                            }),
                            validator: (v) => v == null ? 'مطلوب' : null,
                          ),
                          24.verticalSpace,
                        ],

                        if (parentIdForSub != null) ...[
                          Text(
                            'الفئة الفرعية',
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
                                    'لا توجد فئات فرعية هنا',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  12.verticalSpace,
                                  OutlinedButton.icon(
                                    onPressed:
                                        _addNewSubCategoryForSelectedMain,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('إضافة فئة فرعية'),
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

  void _showAddSubCategoryBottomSheet(
    BuildContext context,
    TransactionCategory parentCategory,
  ) {
    final icons = <String>[
      '🚇',
      '🚆',
      '🚉',
      '🚗',
      '🚕',
      '🚌',
      '🚎',
      '✈️',
      '🚢',
      '🚲',
      '🛵',
      '⛽',

      '🍔',
      '🍕',
      '🍗',
      '🍜',
      '🍩',
      '☕',
      '🍵',
      '🥤',
      '🍎',
      '🍉',

      '🛒',
      '🛍️',
      '🎁',
      '📦',
      '👕',
      '👗',
      '👟',
      '🏠',
      '🛋️',
      '🛏️',
      '🧴',

      '💡',
      '🚰',
      '📱',
      '💻',
      '📺',
      '🔌',
      '🏥',
      '💊',
      '💉',
      '💈',
      '✂️',

      '🎮',
      '🎲',
      '🎬',
      '🎧',
      '🎸',
      '🎫',
      '🎪',
      '⚽',
      '🏀',
      '🏊‍♂️',

      '💰',
      '💵',
      '💳',
      '🏦',
      '💼',
      '📈',
      '📉',
      '📚',
      '✏️',
      '🛠️',
      '🎯',
    ];

    final nameCtrl = TextEditingController();
    var selectedIcon = '🚇';
    final selectedColor = parentCategory.color;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Text(
                              'إضافة فئة جديدة',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'أضف فئة جديدة لتصنيف مصروفاتك',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    24.verticalSpace,

                    Text(
                      'اسم الفئة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    8.verticalSpace,
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'مثال: مواصلات المترو',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                    20.verticalSpace,

                    Text(
                      'الأيقونة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    12.verticalSpace,
                    Container(
                      height: 300.h,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: icons.length,
                        itemBuilder: (context, index) {
                          final icon = icons[index];
                          final isSelected = icon == selectedIcon;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withAlpha(40)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected
                                      ? selectedColor
                                      : Colors.black12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  icon,
                                  style: TextStyle(fontSize: 24.sp),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    32.verticalSpace,

                    CustomPrimaryButton(
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty) {
                          final fullName = '$selectedIcon ${nameCtrl.text}';

                          final newCategory = TransactionCategory(
                            id: const Uuid().v4(),
                            name: fullName,
                            type: parentCategory.type,
                            parentId: parentCategory.id,

                            colorValue: selectedColor.value,
                          );

                          context.read<TransactionCubit>().addCategory(
                            newCategory,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      text: 'إضافة',
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
}

void playTimerSound() {
  final player = AudioPlayer();
  const sound = appSound;
  player.play(AssetSource(sound));
}
