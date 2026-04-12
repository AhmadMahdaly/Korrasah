import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opration/features/auth/presentation/cubit/login_cubit.dart';
import 'package:opration/features/debt/presentation/controllers/debt_cubit/debt_cubit.dart';
import 'package:opration/features/goals/presentation/controllers/financial_goal_cubit/financial_goal_cubit.dart';
import 'package:opration/features/monthly_plan/presentation/controllers/monthly_plan_cubit/monthly_plan_cubit.dart';
import 'package:opration/features/shopping/presentation/controllers/shopping_cubit/shopping_cubit.dart';
import 'package:opration/features/transactions/presentation/controllers/transactions_cubit/transactions_cubit.dart';
import 'package:opration/features/wallets/presentation/cubit/wallet_cubit.dart';

class AppStateReloader {
  static Future<void> reloadAll(BuildContext context) async {
    await context.read<AuthCubit>().checkAuthStatus();
    await context.read<TransactionCubit>().loadInitialData();
    await context.read<WalletCubit>().loadWallets();
    await context.read<FinancialGoalCubit>().loadGoals();
    await context.read<MonthlyPlanCubit>().loadPlanForMonth(DateTime.now());
    context.read<ShoppingCubit>().loadItems();
    context.read<DebtCubit>().loadDebts();
  }
}
