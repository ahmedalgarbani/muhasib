part of 'warehouses_cubit.dart';

abstract class WarehousesState extends Equatable {
  const WarehousesState();
  
  @override
  List<Object?> get props => [];
}

class WarehousesInitial extends WarehousesState {}

class WarehousesLoading extends WarehousesState {}

class WarehousesLoaded extends WarehousesState {
  final List<WarehouseEntity> warehouses;

  const WarehousesLoaded(this.warehouses);

  @override
  List<Object?> get props => [warehouses];
}

class WarehouseCreated extends WarehousesState {
  final int id;

  const WarehouseCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class WarehouseUpdated extends WarehousesState {}

class WarehouseDeleted extends WarehousesState {}

class MainWarehouseSet extends WarehousesState {}

class WarehousesError extends WarehousesState {
  final String message;

  const WarehousesError(this.message);

  @override
  List<Object?> get props => [message];
}
