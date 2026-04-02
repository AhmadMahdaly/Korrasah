import 'package:get_it/get_it.dart';
import 'package:opration/features/Allocation/data/datasource/allocation_local_datasource.dart';
import 'package:opration/features/Allocation/data/repo/allocation_repo_imp.dart';
import 'package:opration/features/Allocation/domain/repo/allocation_repo.dart';
import 'package:opration/features/auth/data/datasources/login_local_data_source.dart';
import 'package:opration/features/auth/data/repositories/login_repository_impl.dart';
import 'package:opration/features/auth/domain/repositories/login_repository.dart';
import 'package:opration/features/auth/domain/usecases/login_usecase.dart';
import 'package:opration/features/auth/presentation/cubit/login_cubit.dart';
import 'package:opration/features/debt/data/repositories/financial_goal_repository_impl.dart';
import 'package:opration/features/debt/presentation/controllers/debt_cubit/debt_cubit.dart';
import 'package:opration/features/goals/data/datasources/financial_goal_local_data_source.dart';
import 'package:opration/features/goals/domain/repositories/financial_goal_repository.dart';
import 'package:opration/features/goals/domain/usecases/add_financial_goal.dart';
import 'package:opration/features/goals/domain/usecases/delete_financial_goal.dart';
import 'package:opration/features/goals/domain/usecases/get_financial_goals.dart';
import 'package:opration/features/goals/domain/usecases/update_financial_goal.dart';
import 'package:opration/features/goals/presentation/controllers/financial_goal_cubit/financial_goal_cubit.dart';
import 'package:opration/features/monthly_plan/domain/usecases/get_budget_summary_usecase.dart';
import 'package:opration/features/monthly_plan/domain/usecases/get_monthly_plan.dart';
import 'package:opration/features/monthly_plan/domain/usecases/save_monthly_plan.dart';
import 'package:opration/features/shopping/presentation/controllers/shopping_cubit/shopping_cubit.dart';
import 'package:opration/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:opration/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:opration/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:opration/features/transactions/domain/usecases/add_category.dart';
import 'package:opration/features/transactions/domain/usecases/delete_category.dart';
import 'package:opration/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:opration/features/transactions/domain/usecases/get_categories.dart';
import 'package:opration/features/transactions/domain/usecases/get_filter_settings.dart';
import 'package:opration/features/transactions/domain/usecases/get_transactions.dart';
import 'package:opration/features/transactions/domain/usecases/process_transaction_usecase.dart';
import 'package:opration/features/transactions/domain/usecases/save_filter_settings.dart';
import 'package:opration/features/transactions/domain/usecases/update_category.dart';
import 'package:opration/features/transactions/domain/usecases/update_transaction.dart';
import 'package:opration/features/wallets/data/datasources/wallet_local_data_source.dart';
import 'package:opration/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:opration/features/wallets/domain/repositories/wallet_repository.dart';
import 'package:opration/features/wallets/domain/usecases/add_wallet.dart';
import 'package:opration/features/wallets/domain/usecases/delete_wallet.dart';
import 'package:opration/features/wallets/domain/usecases/get_wallets.dart';
import 'package:opration/features/wallets/domain/usecases/transfer_balance_usecase.dart';
import 'package:opration/features/wallets/domain/usecases/update_wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final GetIt getIt = GetIt.instance;
Future<void> setupGetIt() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerLazySingleton(() => const Uuid())
    // login
    ..registerLazySingleton(() => LoginUseCase(repository: getIt()))
    ..registerLazySingleton<LoginRepository>(
      () => LoginRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sharedPreferences: getIt()),
    )
    ..registerFactory(() => AuthCubit(localDataSource: getIt()))
    // transactions
    ..registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSourceImpl(
        sharedPreferences: getIt(),
        uuid: getIt(),
      ),
    )
    ..registerLazySingleton<WalletLocalDataSource>(
      () =>
          WalletLocalDataSourceImpl(sharedPreferences: getIt(), uuid: getIt()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(localDataSource: getIt(), uuid: getIt()),
    )
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton(() => DebtCubit(sharedPreferences: getIt()))
    ..registerLazySingleton(() => ShoppingCubit(sharedPreferences: getIt()))
    ..registerLazySingleton(() => GetTransactionsUseCase(repository: getIt()))
    // ..registerLazySingleton(() => AddTransactionUseCase(repository: getIt()))
    ..registerLazySingleton(() => GetCategoriesUseCase(repository: getIt()))
    ..registerLazySingleton(() => AddCategoryUseCase(repository: getIt()))
    ..registerLazySingleton(() => GetFilterSettingsUseCase(repository: getIt()))
    ..registerLazySingleton(
      () => SaveFilterSettingsUseCase(repository: getIt()),
    )
    ..registerLazySingleton(() => UpdateCategoryUseCase(repository: getIt()))
    ..registerLazySingleton(() => DeleteCategoryUseCase(repository: getIt()))
    ..registerLazySingleton(() => UpdateTransactionUseCase(getIt(), getIt()))
    ..registerLazySingleton(() => DeleteTransactionUseCase(getIt(), getIt()))
    ..registerLazySingleton(() => GetMonthlyPlanUseCase(repository: getIt()))
    ..registerLazySingleton(() => SaveMonthlyPlanUseCase(repository: getIt()))
    ..registerLazySingleton(() => UpdateWalletUseCase(repository: getIt()))
    // ..registerLazySingleton(
    //   () => SaveShowMainWalletPrefUseCase(repository: getIt()),
    // )
    // ..registerLazySingleton(() => SetMainWalletUseCase(repository: getIt()))
    ..registerLazySingleton(() => GetWalletsUseCase(repository: getIt()))
    // ..registerLazySingleton(
    //   () => GetShowMainWalletPrefUseCase(repository: getIt()),
    // )
    ..registerLazySingleton(() => DeleteWalletUseCase(repository: getIt()))
    ..registerLazySingleton(() => AddWalletUseCase(repository: getIt()))
    ..registerLazySingleton(() => TransferBalanceUseCase(repository: getIt()))
    ..registerLazySingleton(() => GetBudgetSummaryUseCase(getIt(), getIt()))
    ..registerLazySingleton(
      () => ProcessTransactionUseCase(
        transactionRepo: getIt(),
        walletRepo: getIt(),
      ),
    )
    ..registerLazySingleton<FinancialGoalLocalDataSource>(
      () => FinancialGoalLocalDataSourceImpl(sharedPreferences: getIt()),
    )
    ..registerLazySingleton<AllocationLocalDataSource>(
      () => AllocationLocalDataSourceImpl(sharedPreferences: getIt()),
    )
    ..registerLazySingleton<AllocationRepository>(
      () => AllocationRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<FinancialGoalRepository>(
      () => FinancialGoalRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton(() => GetFinancialGoalsUseCase(repository: getIt()))
    ..registerLazySingleton(() => AddFinancialGoalUseCase(repository: getIt()))
    ..registerLazySingleton(
      () => UpdateFinancialGoalUseCase(repository: getIt()),
    )
    ..registerLazySingleton(
      () => DeleteFinancialGoalUseCase(repository: getIt()),
    )
    ..registerFactory(
      () => FinancialGoalCubit(
        getFinancialGoalsUseCase: getIt(),
        addFinancialGoalUseCase: getIt(),
        updateFinancialGoalUseCase: getIt(),
        deleteFinancialGoalUseCase: getIt(),
      ),
    );
}
