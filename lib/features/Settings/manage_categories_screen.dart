import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:uuid/uuid.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _isExpenseTab = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
        ],
        title: Column(
          children: [
            Text(
              'إعداد الفئات',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _isExpenseTab ? 'تخصيص فئات المصروفات' : 'تخصيص فئات الدخل',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final allCategories = state.allCategories;
          final currentType = _isExpenseTab
              ? TransactionType.expense
              : TransactionType.income;

          final mainCategories = allCategories
              .where((c) => c.type == currentType && c.parentId == null)
              .toList();

          return Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isExpenseTab = false;
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: !_isExpenseTab
                                  ? const Color(0xFF00A86B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Center(
                              child: Text(
                                'فئات المحافظ',
                                style: TextStyle(
                                  color: !_isExpenseTab
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isExpenseTab = true;
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _isExpenseTab
                                  ? const Color(0xFF00A86B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Center(
                              child: Text(
                                'فئات المخصصات',
                                style: TextStyle(
                                  color: _isExpenseTab
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                24.verticalSpace,

                Expanded(
                  child: mainCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dashboard_customize_outlined,
                                size: 60.r,
                                color: Colors.grey.shade300,
                              ),
                              16.verticalSpace,
                              Text(
                                _isExpenseTab
                                    ? 'لا توجد مخصصات مسجلة'
                                    : 'لا توجد محافظ دخل مسجلة',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              8.verticalSpace,
                              Text(
                                'قم بإضافة الميزانية أولاً من شاشة الإعداد',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: mainCategories.length,
                          separatorBuilder: (_, _) => 20.verticalSpace,
                          itemBuilder: (context, index) {
                            final mainCat = mainCategories[index];
                            final subCategories = allCategories
                                .where((c) => c.parentId == mainCat.id)
                                .toList();

                            return _buildMainCategoryGroup(
                              context,
                              mainCat,
                              subCategories,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCategoryGroup(
    BuildContext context,
    TransactionCategory mainCat,
    List<TransactionCategory> subCategories,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              border: const Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mainCat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAddSubCategoryBottomSheet(context, mainCat),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text(
                    'إضافة فئة',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    minimumSize: Size(80.w, 32.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (subCategories.isEmpty)
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Center(
                child: Text(
                  'لم يتم إضافة فئات فرعية لهذا المخصص بعد',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subCategories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = subCategories[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      context.read<TransactionCubit>().deleteCategory(cat.id);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddSubCategoryBottomSheet(
    BuildContext context,
    TransactionCategory parentCategory,
  ) {
    final icons = <String>[
      '🍔',
      '🚗',
      '🎮',
      '💡',
      '🏥',
      '📚',
      '👕',
      '📦',
      '🏠',
      '☕',
      '✈️',
      '🎬',
      '💊',
      '🎁',
      '💰',
      '📱',
      '🛒',
      '🍕',
      '⛽',
      '🎯',
    ];

    final nameCtrl = TextEditingController();
    var selectedIcon = '📦';

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
                top: 40.h,
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
                        hintText: 'مثال: سوبر ماركت',
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
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: icons.map((icon) {
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                20.r,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00A86B)
                                    : Colors.black12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              icon,
                              style: TextStyle(fontSize: 24.sp),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    32.verticalSpace,

                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty) {
                          final fullName = '$selectedIcon ${nameCtrl.text}';

                          final newCategory = TransactionCategory(
                            id: const Uuid().v4(),
                            name: fullName,
                            type: parentCategory.type,
                            parentId: parentCategory.id,
                            colorValue: parentCategory.colorValue,
                          );

                          context.read<TransactionCubit>().addCategory(
                            newCategory,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text(
                        'إضافة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
