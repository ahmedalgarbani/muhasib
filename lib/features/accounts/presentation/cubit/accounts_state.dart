part of 'accounts_cubit.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {}

class AccountsLoading extends AccountsState {}

class AccountsLoaded extends AccountsState {
  final List<AccountEntity> accounts;

  const AccountsLoaded(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class AccountsError extends AccountsState {
  final String message;

  const AccountsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountCreated extends AccountsState {
  final int accountId;

  const AccountCreated(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class AccountUpdated extends AccountsState {}

class AccountDeleted extends AccountsState {}
