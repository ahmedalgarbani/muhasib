part of 'item_movements_cubit.dart';

abstract class ItemMovementsState extends Equatable {
  const ItemMovementsState();

  @override
  List<Object> get props => [];
}

class ItemMovementsInitial extends ItemMovementsState {}

class ItemMovementsLoading extends ItemMovementsState {}

class ItemMovementsLoaded extends ItemMovementsState {
  final List<ItemMovementEntity> movements;

  const ItemMovementsLoaded(this.movements);

  @override
  List<Object> get props => [movements];
}

class ItemMovementsError extends ItemMovementsState {
  final String message;

  const ItemMovementsError(this.message);

  @override
  List<Object> get props => [message];
}
