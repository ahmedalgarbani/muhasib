import 'package:equatable/equatable.dart';
import '../../domain/entities/opening_balance_entity.dart';

abstract class InitialState extends Equatable {
  const InitialState();

  @override
  List<Object?> get props => [];
}

class InitialInitial extends InitialState {
  const InitialInitial();
}

class InitialLoading extends InitialState {
  const InitialLoading();
}

class InitialLoaded extends InitialState {
  final bool isComplete;

  const InitialLoaded({required this.isComplete});

  @override
  List<Object?> get props => [isComplete];
}

class InitialError extends InitialState {
  final String message;

  const InitialError(this.message);

  @override
  List<Object?> get props => [message];
}

class InitialOpeningBalancesSaved extends InitialState {
  const InitialOpeningBalancesSaved();
}

class InitialOpeningBalancesLoaded extends InitialState {
  final List<OpeningBalanceEntity> balances;

  const InitialOpeningBalancesLoaded(this.balances);

  @override
  List<Object?> get props => [balances];
}
