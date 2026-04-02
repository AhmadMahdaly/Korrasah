import 'package:opration/features/Allocation/domain/entities/allocation.dart';

abstract class AllocationRepository {
  Future<List<Allocation>> getAllocations(String yearMonth);
  Future<Allocation> getAllocationById(String id, String yearMonth);
  Future<void> addAllocation(Allocation allocation, String yearMonth);
  Future<void> updateAllocation(Allocation allocation, String yearMonth);
  Future<void> deleteAllocation(String id, String yearMonth);

  Future<void> updateBalanceByCategoryId(
    String categoryId,
    double amountChange,
    String yearMonth,
  );
}
