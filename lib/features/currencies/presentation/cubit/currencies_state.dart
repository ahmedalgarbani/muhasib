part of 'currencies_cubit.dart';

abstract class CurrenciesState extends Equatable {
  const CurrenciesState();

  @override
  List<Object> get props => [];
}

class CurrenciesInitial extends CurrenciesState {}

class CurrenciesLoading extends CurrenciesState {}

class CurrenciesLoaded extends CurrenciesState {
  final List<CurrencyEntity> currencies;

  const CurrenciesLoaded(this.currencies);

  @override
  List<Object> get props => [currencies];
}

class CurrenciesError extends CurrenciesState {
  final String message;
  const CurrenciesError(this.message);

  @override
  List<Object> get props => [message];
}

class CurrencyCreated extends CurrenciesState {
  final int id;
  const CurrencyCreated(this.id);

  @override
  List<Object> get props => [id];
}

class CurrencyUpdated extends CurrenciesState {}

class CurrencyDeleted extends CurrenciesState {}
