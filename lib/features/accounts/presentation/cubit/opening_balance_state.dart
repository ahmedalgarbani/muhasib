part of 'opening_balance_cubit.dart';

abstract class OpeningBalanceState extends Equatable {
  const OpeningBalanceState();

  @override
  List<Object?> get props => [];
}

class OpeningBalanceInitial extends OpeningBalanceState {}

class OpeningBalanceLoading extends OpeningBalanceState {}

class OpeningBalancesLoaded extends OpeningBalanceState {
  final List<OpeningBalanceEntity> openingBalances;

  const OpeningBalancesLoaded(this.openingBalances);

  @override
  List<Object?> get props => [openingBalances];
}

class OpeningBalanceFormReady extends OpeningBalanceState {
  final OpeningBalanceEntity? openingBalance;
  final List<AccountEntity> accounts;

  const OpeningBalanceFormReady({
    this.openingBalance,
    required this.accounts,
  });

  @override
  List<Object?> get props => [openingBalance, accounts];
}

class OpeningBalanceSaving extends OpeningBalanceState {}

class OpeningBalanceSaved extends OpeningBalanceState {}

class OpeningBalancePosting extends OpeningBalanceState {}

class OpeningBalancePosted extends OpeningBalanceState {}

class OpeningBalanceDeleting extends OpeningBalanceState {}

class OpeningBalanceDeleted extends OpeningBalanceState {}

class OpeningBalanceError extends OpeningBalanceState {
  final String message;

  const OpeningBalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
