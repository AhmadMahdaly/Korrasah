import 'package:opration/features/Allocation/data/datasource/allocation_local_datasource.dart';
import 'package:opration/features/Allocation/domain/entities/allocation.dart';
import 'package:opration/features/Allocation/domain/repo/allocation_repo.dart';

class AllocationRepositoryImpl implements AllocationRepository {
  AllocationRepositoryImpl({required this.localDataSource});

  final AllocationLocalDataSource localDataSource;

  @override
  Future<List<Allocation>> getAllocations(String yearMonth) =>
      localDataSource.getAllocations(yearMonth);

  @override
  Future<Allocation> getAllocationById(String id, String yearMonth) =>
      localDataSource.getAllocationById(id, yearMonth);

  @override
  Future<void> addAllocation(Allocation allocation, String yearMonth) =>
      localDataSource.saveAllocation(allocation, yearMonth);

  @override
  Future<void> updateAllocation(Allocation allocation, String yearMonth) =>
      localDataSource.updateAllocation(allocation, yearMonth);

  @override
  Future<void> deleteAllocation(String id, String yearMonth) =>
      localDataSource.deleteAllocation(id, yearMonth);

  @override
  Future<void> updateBalanceByCategoryId(
    String categoryId,
    double amountChange,
    String yearMonth,
  ) => localDataSource.updateBalanceByCategoryId(
    categoryId,
    amountChange,
    yearMonth,
  );
}
