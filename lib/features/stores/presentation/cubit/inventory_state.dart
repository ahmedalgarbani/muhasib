part of 'inventory_cubit.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryEntity> inventories;

  const InventoryLoaded(this.inventories);

  @override
  List<Object> get props => [inventories];
}

class InventoryCreated extends InventoryState {
  final int id;

  const InventoryCreated(this.id);

  @override
  List<Object> get props => [id];
}

class InventoryUpdated extends InventoryState {}

class InventoryPosted extends InventoryState {
  final int id;

  const InventoryPosted(this.id);

  @override
  List<Object> get props => [id];
}

class InventoryDeleted extends InventoryState {}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object> get props => [message];
}
