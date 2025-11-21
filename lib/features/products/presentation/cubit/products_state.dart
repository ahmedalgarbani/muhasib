part of 'products_cubit.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<ProductEntity> products;

  const ProductsLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class ProductCreated extends ProductsState {
  final int id;

  const ProductCreated(this.id);

  @override
  List<Object> get props => [id];
}

class ProductUpdated extends ProductsState {}

class ProductDeleted extends ProductsState {}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object> get props => [message];
}
