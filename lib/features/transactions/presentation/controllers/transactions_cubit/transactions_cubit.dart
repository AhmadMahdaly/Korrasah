import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/domain/usecases/add_category.dart';
import 'package:opration/features/transactions/domain/usecases/delete_category.dart';
import 'package:opration/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:opration/features/transactions/domain/usecases/get_categories.dart';
import 'package:opration/features/transactions/domain/usecases/get_filter_settings.dart';
import 'package:opration/features/transactions/domain/usecases/get_transactions.dart';
// استدعاء الـ UseCases الجديدة الخاصة بالمعاملات المركزية
import 'package:opration/features/transactions/domain/usecases/process_transaction_usecase.dart';
import 'package:opration/features/transactions/domain/usecases/save_filter_settings.dart';
import 'package:opration/features/transactions/domain/usecases/update_category.dart';
import 'package:opration/features/transactions/domain/usecases/update_transaction.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
// استدعاء الـ UseCase الخاص بقراءة المحافظ بدلاً من الـ Cubit
import 'package:opration/features/wallets/domain/usecases/get_wallets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'transactions_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit({
    required this.uuid,
    required this.sharedPreferences,
    required this.getTransactionsUseCase,
    required this.processTransactionUseCase, // الاعتماد الجديد
    required this.updateTransactionUseCase, // الاعتماد الجديد
    required this.deleteTransactionUseCase, // الاعتماد الجديد
    required this.getCategoriesUseCase,
    required this.addCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
    required this.getFilterSettingsUseCase,
    required this.saveFilterSettingsUseCase,
    required this.getWalletsUseCase, // جلب المحافظ للقراءة فقط بدلاً من WalletCubit
  }) : super(const TransactionState());

  final GetTransactionsUseCase getTransactionsUseCase;
  final ProcessTransactionUseCase processTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final AddCategoryUseCase addCategoryUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;
  final GetFilterSettingsUseCase getFilterSettingsUseCase;
  final SaveFilterSettingsUseCase saveFilterSettingsUseCase;
  final GetWalletsUseCase getWalletsUseCase;
  final SharedPreferences sharedPreferences;
  final Uuid uuid;

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final filterSettings = await getFilterSettingsUseCase();
      final lastFilter = filterSettings['activeFilter'] as PredefinedFilter;
      var startDate = filterSettings['startDate'] as DateTime?;
      var endDate = filterSettings['endDate'] as DateTime?;

      if (lastFilter == PredefinedFilter.today ||
          lastFilter == PredefinedFilter.week ||
          lastFilter == PredefinedFilter.month ||
          lastFilter == PredefinedFilter.year) {
        final range = _getDateRangeForFilter(lastFilter, DateTime.now());
        startDate = range.start;
        endDate = range.end;
      }

      final transactions = await getTransactionsUseCase();
      final categories = await getCategoriesUseCase();

      emit(
        state.copyWith(
          isLoading: false,
          filterStartDate: startDate,
          filterEndDate: endDate,
          activeFilter: lastFilter,
          allTransactions: transactions,
          allCategories: categories,
        ),
      );
      await processMonthlySavingsTransfer();
      await checkScheduledTransactions();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  String _getPeriodKey(TransactionCategory category, DateTime date) {
    if (category.recurrenceType == RecurrenceType.monthly) {
      return 'executed_${category.id}_${date.year}_${date.month}';
    } else {
      return 'executed_${category.id}_${date.year}_${date.month}_${date.day}';
    }
  }

  Future<void> processMonthlySavingsTransfer() async {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}_${now.month}';
    final lastTransferMonth = sharedPreferences.getString(
      'last_savings_transfer_month',
    );

    if (lastTransferMonth != currentMonthKey) {
      if (lastTransferMonth == null) {
        await sharedPreferences.setString(
          'last_savings_transfer_month',
          currentMonthKey,
        );
        return;
      }

      try {
        final wallets = await getWalletsUseCase();

        // جلب محفظة التوفير فقط
        final savingsWallet = wallets.firstWhere(
          (w) => w.type == WalletType.savings,
        );

        var hasTransfers = false;

        // المرور على جميع المحافظ الفعلية (المستقلة) لترحيل الفائض منها
        final independentWallets = wallets.where(
          (w) => w.type == WalletType.sideIndependent,
        );

        for (final wallet in independentWallets) {
          if (wallet.balance > 0) {
            // يتم إنشاء معاملة "تحويل" من كل محفظة فعلية إلى التوفير
            final transferTx = Transaction(
              id: uuid.v4(),
              type: TransactionType.transfer,
              amount: wallet.balance,
              date: now,
              fromWalletId: wallet.id,
              toWalletId: savingsWallet.id,
              note: 'ترحيل الفائض التلقائي من ${wallet.name}',
            );

            await processTransactionUseCase.execute(transferTx);
            hasTransfers = true;
          }
        }

        // تحديث السجل المحلي فقط إذا تمت عمليات تحويل بالفعل
        if (hasTransfers) {
          final updatedTransactions = await getTransactionsUseCase();
          emit(state.copyWith(allTransactions: updatedTransactions));
        }
      } catch (e) {
        // يتم التجاهل في حال عدم توفر المحافظ أو حدوث خطأ
      }

      await sharedPreferences.setString(
        'last_savings_transfer_month',
        currentMonthKey,
      );
    }
  }

  Future<void> _markAsExecuted(
    TransactionCategory category,
    DateTime now,
  ) async {
    final periodKey = _getPeriodKey(category, now);
    await sharedPreferences.setBool(periodKey, true);
  }

  Future<void> checkScheduledTransactions() async {
    final now = DateTime.now();
    final pending = <TransactionCategory>[];

    for (final category in state.allCategories.where((c) => c.isRecurring)) {
      var isDue = false;

      if (category.recurrenceType == RecurrenceType.monthly &&
          category.dayOfMonth != null) {
        if (now.day >= category.dayOfMonth!) isDue = true;
      } else if (category.recurrenceType == RecurrenceType.weekly &&
          category.daysOfWeek != null) {
        if (category.daysOfWeek!.contains(now.weekday)) isDue = true;
      }

      if (isDue) {
        final alreadyExecuted = _checkIfAlreadyExecuted(category, now);

        if (!alreadyExecuted) {
          if (category.autoDeduct) {
            await executeRecurringTransaction(category);
          } else {
            pending.add(category);
          }
        }
      }
    }

    if (pending.isNotEmpty || state.pendingTransactions.isNotEmpty) {
      emit(state.copyWith(pendingTransactions: pending));
    }
  }

  bool _checkIfAlreadyExecuted(TransactionCategory category, DateTime now) {
    final periodKey = _getPeriodKey(category, now);
    return sharedPreferences.getBool(periodKey) ?? false;
  }

  Future<void> executeRecurringTransaction(TransactionCategory category) async {
    var finalWalletId = category.targetWalletId ?? '';

    if (finalWalletId.isEmpty) {
      try {
        final wallets = await getWalletsUseCase();
        // نبحث عن محفظة التوفير كخيار افتراضي، وإذا لم يجدها يأخذ أول محفظة في القائمة
        finalWalletId = wallets
            .firstWhere(
              (w) => w.type == WalletType.savings,
              orElse: () => wallets.first,
            )
            .id;
      } catch (_) {
        return;
      }
    }

    final amount = category.fixedAmount ?? 0.0;
    if (amount <= 0) return;

    final newTx = Transaction(
      id: uuid.v4(),
      amount: amount,
      allocationId: category.id,
      date: DateTime.now(),
      type: category.type,
      walletId: finalWalletId,
      note: 'عملية تسجيل تلقائي',
    );

    // سطر واحد فقط يكفي لإدارة التحديث على كافة الـ Layers!
    await processTransactionUseCase.execute(newTx);
    await _markAsExecuted(category, DateTime.now());

    final transactions = await getTransactionsUseCase();
    emit(state.copyWith(allTransactions: transactions));
  }

  Future<void> executeScheduledTransaction(TransactionCategory category) async {
    final transaction = Transaction(
      id: uuid.v4(),
      amount: category.fixedAmount ?? 0,
      allocationId: category.id,
      date: DateTime.now(),
      type: category.type,
      walletId: 'default_wallet',
      note: 'معاملة دورية تلقائية',
    );
    await addTransaction(transaction);
  }

  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    final lastCheck = sharedPreferences.getString('last_recurring_check');

    if (lastCheck == DateFormat('yyyy-MM-dd').format(now)) return;

    for (final category in state.allCategories.where((c) => c.isRecurring)) {
      var shouldProcess = false;

      if (category.recurrenceType == RecurrenceType.monthly &&
          now.day == category.dayOfMonth) {
        shouldProcess = true;
      } else if (category.recurrenceType == RecurrenceType.weekly &&
          category.daysOfWeek!.contains(now.weekday)) {
        shouldProcess = true;
      }

      if (shouldProcess) {
        if (category.autoDeduct) {
          await executeRecurring(category);
        } else {
          emit(
            state.copyWith(
              pendingTransactions: [...state.pendingTransactions, category],
            ),
          );
        }
      }
    }
    await sharedPreferences.setString(
      'last_recurring_check',
      DateFormat('yyyy-MM-dd').format(now),
    );
  }

  Future<void> executeRecurring(TransactionCategory category) async {
    var finalWalletId = category.targetWalletId ?? '';

    if (finalWalletId.isEmpty) {
      try {
        final wallets = await getWalletsUseCase();
        // نبحث عن محفظة التوفير كخيار افتراضي، وإذا لم يجدها يأخذ أول محفظة في القائمة
        finalWalletId = wallets
            .firstWhere(
              (w) => w.type == WalletType.savings,
              orElse: () => wallets.first,
            )
            .id;
      } catch (_) {
        return;
      }
    }

    final newTx = Transaction(
      id: uuid.v4(),
      amount: category.fixedAmount ?? 0,
      allocationId: category.id,
      date: DateTime.now(),
      type: category.type,
      walletId: finalWalletId,
      note: 'تلقائي: ${category.name}',
    );

    await processTransactionUseCase.execute(newTx);

    final transactions = await getTransactionsUseCase();
    emit(state.copyWith(allTransactions: transactions));
  }

  Future<void> setSingleDayFilter(DateTime date) async {
    emit(state.copyWith(isLoading: true));

    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    await saveFilterSettingsUseCase(
      startDate: start,
      endDate: end,
      activeFilter: PredefinedFilter.singleDay,
    );

    emit(
      state.copyWith(
        isLoading: false,
        filterStartDate: start,
        filterEndDate: end,
        activeFilter: PredefinedFilter.singleDay,
      ),
    );
  }

  DateTimeRange _getDateRangeForFilter(PredefinedFilter filter, DateTime now) {
    switch (filter) {
      case PredefinedFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        // التعديل: نهاية اليوم تكون الساعة 11:59:59 مساءً
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case PredefinedFilter.week:
        final daysToSubtract = (now.weekday == DateTime.saturday)
            ? 0
            : (now.weekday + 1) % 7;
        final start = DateTime(now.year, now.month, now.day - daysToSubtract);
        // التعديل: إعطاء مساحة حتى نهاية اليوم الحالي
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case PredefinedFilter.month:
        final start = DateTime(now.year, now.month, 1);
        // التعديل: اليوم 0 يعطينا آخر يوم في الشهر السابق، لذلك نستخدم month + 1 مع اليوم 0
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case PredefinedFilter.year:
        final start = DateTime(now.year, 1, 1);
        // التعديل: حتى آخر لحظة في السنة
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case PredefinedFilter.singleDay:
        final start = state.filterStartDate ?? now;
        final end = DateTime(start.year, start.month, start.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case PredefinedFilter.since:
        return DateTimeRange(
          start: state.filterStartDate ?? now,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case PredefinedFilter.custom:
        return DateTimeRange(
          start: state.filterStartDate ?? now,
          end:
              state.filterEndDate ??
              DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  Future<void> _performDatabaseOperation(
    Future<void> Function() operation,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await operation();

      final transactions = await getTransactionsUseCase();
      final categories = await getCategoriesUseCase();
      emit(
        state.copyWith(
          isLoading: false,
          allTransactions: transactions,
          allCategories: categories,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // =====================================
  // العمليات المركزية للمعاملات
  // =====================================

  Future<void> addTransaction(Transaction transaction) async {
    await _performDatabaseOperation(
      () => processTransactionUseCase.execute(transaction),
    );
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    await _performDatabaseOperation(
      () => updateTransactionUseCase.execute(updatedTransaction),
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _performDatabaseOperation(
      () => deleteTransactionUseCase.execute(transactionId),
    );
  }

  // =====================================
  // عمليات الفئات (Categories)
  // =====================================

  Future<void> addCategory(TransactionCategory category) async {
    await _performDatabaseOperation(() => addCategoryUseCase(category));
  }

  Future<void> updateCategory(TransactionCategory category) async {
    await _performDatabaseOperation(() => updateCategoryUseCase(category));
  }

  Future<void> deleteCategory(String categoryId) async {
    emit(state.copyWith(isLoading: true));
    try {
      // 1. تحديد المعاملات المربوطة بهذه الفئة
      final transactionsToDelete = state.allTransactions
          .where((t) => t.allocationId == categoryId)
          .toList();

      // 2. استخدام الـ UseCase لكل معاملة لضمان استرجاع أرصدة المحافظ بدقة عالية
      for (final transaction in transactionsToDelete) {
        await deleteTransactionUseCase.execute(transaction.id);
      }

      // 3. حذف الفئة نفسها بشكل آمن
      await deleteCategoryUseCase(categoryId);

      // 4. تحديث الـ State بالبيانات النظيفة
      final transactions = await getTransactionsUseCase();
      final categories = await getCategoriesUseCase();
      emit(
        state.copyWith(
          isLoading: false,
          allTransactions: transactions,
          allCategories: categories,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // =====================================
  // إعدادات الفلترة
  // =====================================

  Future<void> setSinceFilter(DateTime startDate) async {
    emit(state.copyWith(isLoading: true));
    final endDate = DateTime.now();
    await saveFilterSettingsUseCase(
      startDate: startDate,
      endDate: endDate,
      activeFilter: PredefinedFilter.since,
    );
    emit(
      state.copyWith(
        isLoading: false,
        filterStartDate: startDate,
        filterEndDate: endDate,
        activeFilter: PredefinedFilter.since,
      ),
    );
  }

  Future<void> setPredefinedFilter(PredefinedFilter filter) async {
    emit(state.copyWith(isLoading: true));
    final range = _getDateRangeForFilter(filter, DateTime.now());
    await saveFilterSettingsUseCase(
      startDate: range.start,
      endDate: range.end,
      activeFilter: filter,
    );
    emit(
      state.copyWith(
        isLoading: false,
        filterStartDate: range.start,
        filterEndDate: range.end,
        activeFilter: filter,
      ),
    );
  }

  Future<void> setCustomDateFilter(DateTime startDate, DateTime endDate) async {
    emit(state.copyWith(isLoading: true));
    await saveFilterSettingsUseCase(
      startDate: startDate,
      endDate: endDate,
      activeFilter: PredefinedFilter.custom,
    );
    emit(
      state.copyWith(
        isLoading: false,
        filterStartDate: startDate,
        filterEndDate: endDate,
        activeFilter: PredefinedFilter.custom,
      ),
    );
  }

  void setWalletFilter(String? walletId) {
    if (walletId == null) {
      emit(state.copyWith(clearSelectedWalletId: true));
    } else {
      emit(state.copyWith(selectedWalletId: walletId));
    }
  }

  Future<void> approvePendingTransaction(TransactionCategory category) async {
    final updatedPending = state.pendingTransactions
        .where((c) => c.id != category.id)
        .toList();
    emit(state.copyWith(pendingTransactions: updatedPending));

    await executeRecurringTransaction(category);
  }

  Future<void> dismissPendingTransaction(TransactionCategory category) async {
    final updatedPending = state.pendingTransactions
        .where((c) => c.id != category.id)
        .toList();
    emit(state.copyWith(pendingTransactions: updatedPending));

    await _markAsExecuted(category, DateTime.now());
  }
}
