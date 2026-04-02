import 'dart:convert';

import 'package:opration/features/Allocation/domain/entities/allocation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AllocationLocalDataSource {
  Future<List<Allocation>> getAllocations(String yearMonth);
  Future<Allocation> getAllocationById(String id, String yearMonth);
  Future<void> saveAllocation(Allocation allocation, String yearMonth);
  Future<void> updateAllocation(Allocation allocation, String yearMonth);
  Future<void> deleteAllocation(String id, String yearMonth);
  Future<void> updateBalanceByCategoryId(
    String categoryId,
    double amountChange,
    String yearMonth,
  );
}

class AllocationLocalDataSourceImpl implements AllocationLocalDataSource {
  AllocationLocalDataSourceImpl({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  String _getKey(String yearMonth) => 'allocations_$yearMonth';

  Future<List<Map<String, dynamic>>> _getDecodedList(String key) async {
    final jsonString = sharedPreferences.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      return (json.decode(jsonString) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> _saveEncodedList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    await sharedPreferences.setString(key, json.encode(list));
  }

  @override
  Future<List<Allocation>> getAllocations(String yearMonth) async {
    final list = await _getDecodedList(_getKey(yearMonth));
    return list.map(Allocation.fromJson).toList();
  }

  @override
  Future<Allocation> getAllocationById(String id, String yearMonth) async {
    final list = await _getDecodedList(_getKey(yearMonth));
    final jsonMap = list.firstWhere(
      (a) => a['id'] == id,
      orElse: () => throw Exception('المخصص غير موجود في هذا الشهر'),
    );
    return Allocation.fromJson(jsonMap);
  }

  @override
  Future<void> saveAllocation(Allocation allocation, String yearMonth) async {
    final key = _getKey(yearMonth);
    final list = await _getDecodedList(key);
    list.add(allocation.toJson());
    await _saveEncodedList(key, list);
  }

  @override
  Future<void> updateAllocation(Allocation allocation, String yearMonth) async {
    final key = _getKey(yearMonth);
    final list = await _getDecodedList(key);
    final index = list.indexWhere((a) => a['id'] == allocation.id);

    if (index != -1) {
      list[index] = allocation.toJson();
      await _saveEncodedList(key, list);
    } else {
      throw Exception('لا يمكن تحديث مخصص غير موجود');
    }
  }

  @override
  Future<void> deleteAllocation(String id, String yearMonth) async {
    final key = _getKey(yearMonth);
    final list = await _getDecodedList(key);
    list.removeWhere((a) => a['id'] == id);
    await _saveEncodedList(key, list);
  }

  @override
  Future<void> updateBalanceByCategoryId(
    String categoryId,
    double amountChange,
    String yearMonth,
  ) async {
    final key = _getKey(yearMonth);
    final list = await _getDecodedList(key);

    final index = list.indexWhere((a) => a['categoryId'] == categoryId);

    if (index != -1) {
      final oldAllocation = Allocation.fromJson(list[index]);

      // تحديث الرصيد. إذا كان amountChange بالسالب (مصروف)، سيقل الرصيد.
      // الرصيد يمكن أن يكون بالسالب هنا بحسب قواعد عمل التطبيق.
      final newBalance = oldAllocation.balance + amountChange;
      final updatedAllocation = oldAllocation.copyWith(balance: newBalance);

      list[index] = updatedAllocation.toJson();
      await _saveEncodedList(key, list);
    } else {
      // إذا تم اختيار فئة ليس لها مخصص، يتم إلقاء استثناء للحفاظ على سلامة الـ Layers
      throw Exception(
        'لم يتم العثور على مخصص مرتبط بهذه الفئة في شهر $yearMonth',
      );
    }
  }
}
