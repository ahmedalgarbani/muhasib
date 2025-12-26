part of 'account_limits_cubit.dart';

abstract class AccountLimitsState extends Equatable {
  const AccountLimitsState();

  @override
  List<Object?> get props => [];
}

class AccountLimitsInitial extends AccountLimitsState {}

class AccountLimitsLoading extends AccountLimitsState {}

class AccountLimitsLoaded extends AccountLimitsState {
  final List<AccountLimitEntity> limits;
  final String? message;

  const AccountLimitsLoaded(this.limits, {this.message});

  @override
  List<Object?> get props => [limits, message];
}

class AccountLimitsError extends AccountLimitsState {
  final String message;

  const AccountLimitsError(this.message);

  @override
  List<Object?> get props => [message];
}
