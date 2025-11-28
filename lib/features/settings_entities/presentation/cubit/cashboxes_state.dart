part of 'cashboxes_cubit.dart';

abstract class CashboxesState extends Equatable {
  const CashboxesState();

  @override
  List<Object?> get props => [];
}

class CashboxesInitial extends CashboxesState {}

class CashboxesLoading extends CashboxesState {}

class CashboxesLoaded extends CashboxesState {
  final List<CashboxEntity> cashboxes;

  const CashboxesLoaded(this.cashboxes);

  @override
  List<Object?> get props => [cashboxes];
}

class CashboxCreated extends CashboxesState {
  final int id;

  const CashboxCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class CashboxUpdated extends CashboxesState {}

class CashboxDeleted extends CashboxesState {}

class MainCashboxSet extends CashboxesState {}

class CashboxesError extends CashboxesState {
  final String message;

  const CashboxesError(this.message);

  @override
  List<Object?> get props => [message];
}

