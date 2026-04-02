import 'dart:convert';

import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:opration/features/monthly_plan/domain/entities/monthly_plan.dart';
import 'package:opration/features/transactions/domain/entities/transaction.dart';
import 'package:opration/features/transactions/domain/entities/transaction_category.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class TransactionLocalDataSource {
  Future<List<Transaction>> getTransactions();
  Future<Transaction> getTransactionById(String id);
  Future<void> saveTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String transactionId);

  Future<List<TransactionCategory>> getCategories();
  Future<void> saveCategory(TransactionCategory category);
  Future<void> updateCategory(TransactionCategory category);
  Future<void> deleteCategory(String categoryId);

  Future<void> saveDateFilter(
    DateTime startDate,
    DateTime endDate,
    PredefinedFilter activeFilter,
  );
  Future<Map<String, dynamic>> getDateFilter();

  Future<MonthlyPlan> getMonthlyPlan(String yearMonth);
  Future<void> saveMonthlyPlan(MonthlyPlan plan);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  TransactionLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.uuid,
  });

  final SharedPreferences sharedPreferences;
  final Uuid uuid;

  // دالة مساعدة لفك تشفير القوائم وتجنب التكرار
  Future<List<Map<String, dynamic>>> _getDecodedList(String key) async {
    final jsonString = sharedPreferences.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // دالة مساعدة لتشفير وحفظ القوائم
  Future<void> _saveEncodedList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    await sharedPreferences.setString(key, json.encode(list));
  }

  // ==========================================
  // قسم المعاملات (Transactions)
  // ==========================================

  @override
  Future<List<Transaction>> getTransactions() async {
    final list = await _getDecodedList(CacheKeys.cachedTransactions);
    return list.map(Transaction.fromJson).toList();
  }

  @override
  Future<Transaction> getTransactionById(String id) async {
    final list = await _getDecodedList(CacheKeys.cachedTransactions);
    final jsonMap = list.firstWhere(
      (t) => t['id'] == id,
      orElse: () => throw Exception('المعاملة غير موجودة في قاعدة البيانات'),
    );
    return Transaction.fromJson(jsonMap);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final list = await _getDecodedList(CacheKeys.cachedTransactions);
    list.add(transaction.toJson());
    await _saveEncodedList(CacheKeys.cachedTransactions, list);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final list = await _getDecodedList(CacheKeys.cachedTransactions);
    final index = list.indexWhere((t) => t['id'] == transaction.id);
    if (index != -1) {
      list[index] = transaction.toJson();
      await _saveEncodedList(CacheKeys.cachedTransactions, list);
    } else {
      throw Exception('لا يمكن تحديث معاملة غير موجودة');
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final list = await _getDecodedList(CacheKeys.cachedTransactions);
    list.removeWhere((t) => t['id'] == transactionId);
    await _saveEncodedList(CacheKeys.cachedTransactions, list);
  }

  // ==========================================
  // قسم الفئات / المخصصات (Categories / Allocations)
  // ==========================================

  @override
  Future<List<TransactionCategory>> getCategories() async {
    final list = await _getDecodedList(CacheKeys.cachedCategories);
    if (list.isNotEmpty) {
      return list.map(TransactionCategory.fromJson).toList();
    } else {
      final defaultCategories = <TransactionCategory>[];
      await _saveEncodedList(
        CacheKeys.cachedCategories,
        defaultCategories.map((c) => c.toJson()).toList(),
      );
      return defaultCategories;
    }
  }

  @override
  Future<void> saveCategory(TransactionCategory category) async {
    final list = await _getDecodedList(CacheKeys.cachedCategories);
    list.add(category.toJson());
    await _saveEncodedList(CacheKeys.cachedCategories, list);
  }

  @override
  Future<void> updateCategory(TransactionCategory category) async {
    final list = await _getDecodedList(CacheKeys.cachedCategories);
    final index = list.indexWhere((c) => c['id'] == category.id);
    if (index != -1) {
      list[index] = category.toJson();
      await _saveEncodedList(CacheKeys.cachedCategories, list);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // 1. مسح الفئة
    final list = await _getDecodedList(CacheKeys.cachedCategories);
    list.removeWhere((c) => c['id'] == categoryId);
    await _saveEncodedList(CacheKeys.cachedCategories, list);

    // 2. مسح المعاملات المرتبطة بهذه الفئة (Cascading Delete)
    final transactions = await _getDecodedList(CacheKeys.cachedTransactions);
    transactions.removeWhere((t) => t['categoryId'] == categoryId);
    await _saveEncodedList(CacheKeys.cachedTransactions, transactions);
  }

  // ==========================================
  // قسم الفلترة وإعدادات التاريخ
  // ==========================================

  @override
  Future<void> saveDateFilter(
    DateTime startDate,
    DateTime endDate,
    PredefinedFilter activeFilter,
  ) async {
    await sharedPreferences.setString(
      CacheKeys.cachedFilterStartDate,
      startDate.toIso8601String(),
    );
    await sharedPreferences.setString(
      CacheKeys.cachedFilterEndDate,
      endDate.toIso8601String(),
    );
    await sharedPreferences.setString(
      CacheKeys.cachedActiveFilter,
      activeFilter.name,
    );
  }

  @override
  Future<Map<String, dynamic>> getDateFilter() async {
    final startDateString = sharedPreferences.getString(
      CacheKeys.cachedFilterStartDate,
    );
    final endDateString = sharedPreferences.getString(
      CacheKeys.cachedFilterEndDate,
    );
    final activeFilterString = sharedPreferences.getString(
      CacheKeys.cachedActiveFilter,
    );

    final activeFilter = PredefinedFilter.values.firstWhere(
      (e) => e.name == activeFilterString,
      orElse: () => PredefinedFilter.month,
    );

    return {
      'startDate': startDateString != null
          ? DateTime.parse(startDateString)
          : null,
      'endDate': endDateString != null ? DateTime.parse(endDateString) : null,
      'activeFilter': activeFilter,
    };
  }

  // ==========================================
  // قسم الخطة الشهرية (Monthly Plan)
  // ==========================================

  String _getPlanCacheKey(String yearMonth) => 'monthly_plan_$yearMonth';

  @override
  Future<MonthlyPlan> getMonthlyPlan(String yearMonth) async {
    final jsonString = sharedPreferences.getString(_getPlanCacheKey(yearMonth));
    MonthlyPlan plan;

    if (jsonString != null && jsonString.isNotEmpty) {
      plan = MonthlyPlan.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    } else {
      plan = MonthlyPlan(id: yearMonth);
    }

    // التأكد من وجود الدخل الافتراضي (الراتب)
    if (!plan.incomes.any((i) => i.id == 'default_salary')) {
      final defaultSalary = PlannedIncome(
        id: 'default_salary',
        name: 'الراتب',
        amount: 0.0,
        date: DateTime.now(),
        executionDay: 1,
        executionType: PlanExecutionType.manual,
      );

      plan = plan.copyWith(incomes: [defaultSalary, ...plan.incomes]);
    }

    return plan;
  }

  @override
  Future<void> saveMonthlyPlan(MonthlyPlan plan) async {
    final key = _getPlanCacheKey(plan.id);
    await sharedPreferences.setString(key, json.encode(plan.toJson()));
  }
}
