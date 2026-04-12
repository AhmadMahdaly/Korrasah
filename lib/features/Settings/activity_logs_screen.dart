import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/services/app_settings_store.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/core/theme/text_style.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

enum _LogFilter { all, income, expense, transfer, reallocation }

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  _LogFilter _filter = _LogFilter.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const PageHeader(
        isLeading: true,
        heightBar: 86,
        title: 'السجلات',
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, transactionState) {
          return BlocBuilder<WalletCubit, WalletState>(
            builder: (context, walletState) {
              final wallets = walletState is WalletLoaded
                  ? walletState.wallets
                  : const <Wallet>[];
              final filteredTransactions =
                  transactionState.allTransactions
                      .where(_matchesFilter)
                      .where(_matchesSearch)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

              final totalLogs = transactionState.allTransactions.length;
              final totalTransfers = transactionState.allTransactions
                  .where((item) => item.type == TransactionType.transfer)
                  .length;
              final visibleLogs = filteredTransactions.length;

              return ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'إجمالي السجلات',
                          value: '$totalLogs',
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'المعروض الآن',
                          value: '$visibleLogs',
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'التحويلات',
                          value: '$totalTransfers',
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  TextField(
                    onChanged: (value) {
                      setState(() => _search = value.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث في الوصف أو الملاحظة',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.r),
                        borderSide: BorderSide(
                          color: Colors.black.withAlpha(15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.r),
                        borderSide: BorderSide(
                          color: Colors.black.withAlpha(15),
                        ),
                      ),
                    ),
                  ),
                  14.verticalSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _LogFilter.values.map((item) {
                        final selected = item == _filter;
                        return Padding(
                          padding: EdgeInsetsDirectional.only(end: 8.w),
                          child: ChoiceChip(
                            label: Text(_labelForFilter(item)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _filter = item);
                            },
                            labelStyle: AppTextStyle.style12Bold.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.primaryTextColor,
                            ),
                            selectedColor: AppColors.primaryColor,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.black.withAlpha(15),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  16.verticalSpace,
                  if (filteredTransactions.isEmpty)
                    const _LogsEmptyState()
                  else
                    ...filteredTransactions.map((transaction) {
                      String? walletName;
                      for (final wallet in wallets) {
                        if (wallet.id == transaction.walletId) {
                          walletName = wallet.name;
                          break;
                        }
                      }
                      return _LogTile(
                        transaction: transaction,
                        walletName: walletName,
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesFilter(Transaction transaction) {
    switch (_filter) {
      case _LogFilter.all:
        return true;
      case _LogFilter.income:
        return transaction.type == TransactionType.income;
      case _LogFilter.expense:
        return transaction.type == TransactionType.expense;
      case _LogFilter.transfer:
        return transaction.type == TransactionType.transfer;
      case _LogFilter.reallocation:
        return transaction.type == TransactionType.reallocation;
    }
  }

  bool _matchesSearch(Transaction transaction) {
    if (_search.isEmpty) return true;
    final note = transaction.note?.toLowerCase() ?? '';
    final descriptor = _titleForTransaction(transaction).toLowerCase();
    return note.contains(_search.toLowerCase()) ||
        descriptor.contains(_search.toLowerCase());
  }

  String _labelForFilter(_LogFilter filter) {
    switch (filter) {
      case _LogFilter.all:
        return 'الكل';
      case _LogFilter.income:
        return 'دخل';
      case _LogFilter.expense:
        return 'مصروف';
      case _LogFilter.transfer:
        return 'تحويل';
      case _LogFilter.reallocation:
        return 'إعادة توزيع';
    }
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyle.style20Bold.copyWith(color: Colors.white),
          ),
          6.verticalSpace,
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.style9Bold.copyWith(
              color: Colors.white.withAlpha(190),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.transaction,
    required this.walletName,
  });

  final Transaction transaction;
  final String? walletName;

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsStore(sharedPreferences: getIt());
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.errorColor : AppColors.primaryColor;
    final sign = isExpense ? '-' : '+';
    assert(appSettings.currencySymbol.isNotEmpty);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  _iconForTransaction(transaction.type),
                  color: color,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleForTransaction(transaction),
                      style: AppTextStyle.style14W700.copyWith(
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      transaction.note?.trim().isNotEmpty ?? false
                          ? transaction.note!
                          : 'تم تسجيل حركة مالية داخل التطبيق',
                      style: AppTextStyle.style12W400.copyWith(
                        color: AppColors.textGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${transaction.amount.toStringAsFixed(2)} ج.م',
                style: AppTextStyle.style14W700.copyWith(color: color),
              ),
            ],
          ),
          12.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _MetaBadge(text: _typeLabel(transaction.type)),
              _MetaBadge(
                text: walletName == null ? 'بدون محفظة' : walletName!,
              ),
              _MetaBadge(
                text: DateFormat(
                  'd MMM yyyy - h:mm a',
                  'ar',
                ).format(transaction.date),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: AppTextStyle.style9Bold.copyWith(
          color: AppColors.primaryTextColor,
        ),
      ),
    );
  }
}

class _LogsEmptyState extends StatelessWidget {
  const _LogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 54.r,
            color: AppColors.textGreyColor,
          ),
          12.verticalSpace,
          Text(
            'لا توجد نتائج مطابقة حاليًا',
            style: AppTextStyle.style16W600.copyWith(
              color: AppColors.primaryTextColor,
            ),
          ),
          8.verticalSpace,
          Text(
            'جرّب تغيير الفلاتر أو حذف نص البحث.',
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

String _titleForTransaction(Transaction transaction) {
  switch (transaction.type) {
    case TransactionType.income:
      return 'إضافة دخل';
    case TransactionType.expense:
      return 'تسجيل مصروف';
    case TransactionType.transfer:
      return 'تحويل بين المحافظ';
    case TransactionType.reallocation:
      return 'إعادة توزيع';
  }
}

String _typeLabel(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return 'دخل';
    case TransactionType.expense:
      return 'مصروف';
    case TransactionType.transfer:
      return 'تحويل';
    case TransactionType.reallocation:
      return 'إعادة توزيع';
  }
}

IconData _iconForTransaction(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return Icons.south_west_rounded;
    case TransactionType.expense:
      return Icons.north_east_rounded;
    case TransactionType.transfer:
      return Icons.swap_horiz_rounded;
    case TransactionType.reallocation:
      return Icons.pie_chart_outline_rounded;
  }
}
