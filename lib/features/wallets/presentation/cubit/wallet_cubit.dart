import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opration/features/wallets/domain/entities/wallet.dart';
import 'package:opration/features/wallets/domain/usecases/add_wallet.dart';
import 'package:opration/features/wallets/domain/usecases/delete_wallet.dart';
import 'package:opration/features/wallets/domain/usecases/get_wallets.dart';
import 'package:opration/features/wallets/domain/usecases/transfer_balance_usecase.dart';
import 'package:opration/features/wallets/domain/usecases/update_wallet.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({
    required this.transferBalanceUseCase,
    required this.getWalletsUseCase,
    required this.addWalletUseCase,
    required this.updateWalletUseCase,
    required this.deleteWalletUseCase,
  }) : super(WalletInitial());

  final GetWalletsUseCase getWalletsUseCase;
  final AddWalletUseCase addWalletUseCase;
  final UpdateWalletUseCase updateWalletUseCase;
  final DeleteWalletUseCase deleteWalletUseCase;
  final TransferBalanceUseCase transferBalanceUseCase;

  Future<void> loadWallets() async {
    try {
      emit(WalletLoading());
      final wallets = await getWalletsUseCase();
      emit(WalletLoaded(wallets));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _performOperation(Future<void> Function() operation) async {
    if (state is! WalletLoaded) return;

    final originalState = state as WalletLoaded;
    final originalWallets = originalState.wallets;

    try {
      await operation();
      await loadWallets();
    } catch (e) {
      emit(WalletError(e.toString()));
      emit(WalletLoaded(originalWallets));
    }
  }

  Future<void> addWallet(Wallet wallet) async {
    await _performOperation(() => addWalletUseCase(wallet));
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _performOperation(() => updateWalletUseCase(wallet));
  }

  Future<void> deleteWallet(String walletId) async {
    await _performOperation(() => deleteWalletUseCase(walletId));
  }

  Future<void> transferBalance(
    String fromId,
    String toId,
    double amount,
  ) async {
    await _performOperation(() async {
      await transferBalanceUseCase(fromId, toId, amount);
    });
  }
}
