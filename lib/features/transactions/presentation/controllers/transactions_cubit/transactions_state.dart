part of 'transactions_cubit.dart';

enum PredefinedFilter { today, week, month, year, singleDay, since, custom }

class TransactionState extends Equatable {
  const TransactionState({
    this.isLoading = false,
    this.allTransactions = const [],
    this.allCategories = const [],
    this.pendingTransactions = const [],
    this.filterStartDate,
    this.filterEndDate,
    this.activeFilter = PredefinedFilter.month,
    this.selectedWalletId,
    this.error,
  });

  final bool isLoading;
  final List<Transaction> allTransactions;
  final List<TransactionCategory> allCategories;
  final List<TransactionCategory> pendingTransactions;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final PredefinedFilter activeFilter;
  final String? selectedWalletId;
  final String? error;

  List<Transaction> get filteredTransactions {
    final filtered = allTransactions.where((tx) {
      if (selectedWalletId != null && tx.walletId != selectedWalletId) {
        return false;
      }

      // 2. الفلترة بتاريخ البداية
      if (filterStartDate != null && tx.date.isBefore(filterStartDate!)) {
        return false;
      }

      // 3. الفلترة بتاريخ النهاية
      if (filterEndDate != null && tx.date.isAfter(filterEndDate!)) {
        return false;
      }

      return true;
    }).toList();

    return filtered;
  }

  TransactionState copyWith({
    bool? isLoading,
    List<Transaction>? allTransactions,
    List<TransactionCategory>? allCategories,
    List<TransactionCategory>? pendingTransactions,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    PredefinedFilter? activeFilter,
    String? selectedWalletId,
    bool clearSelectedWalletId = false,
    String? error,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      allTransactions: allTransactions ?? this.allTransactions,
      allCategories: allCategories ?? this.allCategories,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedWalletId: clearSelectedWalletId
          ? null
          : (selectedWalletId ?? this.selectedWalletId),
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    allTransactions,
    allCategories,
    pendingTransactions,
    filterStartDate,
    filterEndDate,
    activeFilter,
    selectedWalletId,
    error,
  ];
}
