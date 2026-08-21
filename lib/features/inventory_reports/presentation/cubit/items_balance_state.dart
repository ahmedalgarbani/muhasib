part of 'items_balance_cubit.dart';

abstract class ItemsBalanceState extends Equatable {
  const ItemsBalanceState();
  @override
  List<Object?> get props => [];
}

class ItemsBalanceInitial extends ItemsBalanceState {}

class ItemsBalanceLoading extends ItemsBalanceState {}

class ItemsBalanceLoaded extends ItemsBalanceState {
  final List<ItemsBalanceEntity> balances;
  const ItemsBalanceLoaded({required this.balances});
  @override
  List<Object?> get props => [balances];
}

class ItemsBalanceEmpty extends ItemsBalanceState {}

class ItemsBalanceError extends ItemsBalanceState {
  final String message;
  const ItemsBalanceError(this.message);
  @override
  List<Object?> get props => [message];
}
