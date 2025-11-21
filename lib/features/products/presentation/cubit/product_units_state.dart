part of 'product_units_cubit.dart';

abstract class ProductUnitsState extends Equatable {
  const ProductUnitsState();

  @override
  List<Object> get props => [];
}

class ProductUnitsInitial extends ProductUnitsState {}

class ProductUnitsLoading extends ProductUnitsState {}

class ProductUnitsLoaded extends ProductUnitsState {
  final List<ProductUnitEntity> units;

  const ProductUnitsLoaded(this.units);

  @override
  List<Object> get props => [units];
}

class ProductUnitCreated extends ProductUnitsState {
  final int id;

  const ProductUnitCreated(this.id);

  @override
  List<Object> get props => [id];
}

class ProductUnitUpdated extends ProductUnitsState {}

class ProductUnitDeleted extends ProductUnitsState {}

class ProductUnitsError extends ProductUnitsState {
  final String message;

  const ProductUnitsError(this.message);

  @override
  List<Object> get props => [message];
}
