part of 'account_connect_cubit.dart';

abstract class AccountConnectState extends Equatable {
  const AccountConnectState();

  @override
  List<Object?> get props => [];
}

class AccountConnectInitial extends AccountConnectState {}

class AccountConnectLoading extends AccountConnectState {}

class AccountConnectsLoaded extends AccountConnectState {
  final List<AccountConnectEntity> accountConnects;

  const AccountConnectsLoaded(this.accountConnects);

  @override
  List<Object?> get props => [accountConnects];
}

class AccountConnectCreated extends AccountConnectState {
  final int id;

  const AccountConnectCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class AccountConnectUpdated extends AccountConnectState {}

class AccountConnectDeleted extends AccountConnectState {}

class AccountConnectError extends AccountConnectState {
  final String message;

  const AccountConnectError(this.message);

  @override
  List<Object?> get props => [message];
}
