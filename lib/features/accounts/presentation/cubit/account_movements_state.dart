import 'package:equatable/equatable.dart';
import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';

abstract class AccountMovementsState extends Equatable {
  const AccountMovementsState();

  @override
  List<Object?> get props => [];
}

class AccountMovementsInitial extends AccountMovementsState {}

class AccountMovementsLoading extends AccountMovementsState {}

class AccountMovementsLoaded extends AccountMovementsState {
  final List<AccountMovementEntity> movements;
  final AccountMovementsSummary summary;
  final DateTime startDate;
  final DateTime endDate;

  const AccountMovementsLoaded({
    required this.movements,
    required this.summary,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [movements, summary, startDate, endDate];
}

class AccountMovementsError extends AccountMovementsState {
  final String message;

  const AccountMovementsError({required this.message});

  @override
  List<Object?> get props => [message];
}
