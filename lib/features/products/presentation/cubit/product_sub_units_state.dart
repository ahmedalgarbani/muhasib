part of 'product_sub_units_cubit.dart';

abstract class ProductSubUnitsState extends Equatable {
  const ProductSubUnitsState();

  @override
  List<Object> get props => [];
}

class ProductSubUnitsInitial extends ProductSubUnitsState {}

class ProductSubUnitsLoading extends ProductSubUnitsState {}

class ProductSubUnitsLoaded extends ProductSubUnitsState {
  final List<ProductSubUnitEntity> subUnits;

  const ProductSubUnitsLoaded(this.subUnits);

  @override
  List<Object> get props => [subUnits];
}

class ProductSubUnitCreated extends ProductSubUnitsState {
  final int id;

  const ProductSubUnitCreated(this.id);

  @override
  List<Object> get props => [id];
}

class ProductSubUnitUpdated extends ProductSubUnitsState {}

class ProductSubUnitDeleted extends ProductSubUnitsState {}

class ProductSubUnitMainSet extends ProductSubUnitsState {}

class ProductSubUnitsError extends ProductSubUnitsState {
  final String message;

  const ProductSubUnitsError(this.message);

  @override
  List<Object> get props => [message];
}
