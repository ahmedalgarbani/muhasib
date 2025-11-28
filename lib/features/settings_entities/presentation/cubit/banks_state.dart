part of 'banks_cubit.dart';

abstract class BanksState extends Equatable {
  const BanksState();

  @override
  List<Object?> get props => [];
}

class BanksInitial extends BanksState {}

class BanksLoading extends BanksState {}

class BanksLoaded extends BanksState {
  final List<BankEntity> banks;

  const BanksLoaded(this.banks);

  @override
  List<Object?> get props => [banks];
}

class BankCreated extends BanksState {
  final int id;

  const BankCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class BankUpdated extends BanksState {}

class BankDeleted extends BanksState {}

class BanksError extends BanksState {
  final String message;

  const BanksError(this.message);

  @override
  List<Object?> get props => [message];
}

