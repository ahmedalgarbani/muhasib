part of 'item_movement_cubit.dart';

abstract class ItemMovementState extends Equatable {
  const ItemMovementState();
  @override
  List<Object?> get props => [];
}

class ItemMovementInitial extends ItemMovementState {}

class ItemMovementLoading extends ItemMovementState {}

class ItemMovementLoaded extends ItemMovementState {
  final List<ItemMovementEntity> movements;
  const ItemMovementLoaded({required this.movements});
  @override
  List<Object?> get props => [movements];
}

class ItemMovementEmpty extends ItemMovementState {}

class ItemMovementError extends ItemMovementState {
  final String message;
  const ItemMovementError(this.message);
  @override
  List<Object?> get props => [message];
}
