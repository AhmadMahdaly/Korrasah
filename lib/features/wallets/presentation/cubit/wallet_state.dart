part of 'wallet_cubit.dart';

// ----- Wallet State (يمكن وضعها في ملف منفصل كما تفعل عادة) -----
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  const WalletLoaded(this.wallets);
  final List<Wallet> wallets;

  @override
  List<Object> get props => [wallets];
}

class WalletError extends WalletState {
  const WalletError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
