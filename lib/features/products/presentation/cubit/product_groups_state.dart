part of 'product_groups_cubit.dart';

abstract class ProductGroupsState extends Equatable {
  const ProductGroupsState();

  @override
  List<Object> get props => [];
}

class ProductGroupsInitial extends ProductGroupsState {}

class ProductGroupsLoading extends ProductGroupsState {}

class ProductGroupsLoaded extends ProductGroupsState {
  final List<ProductGroupEntity> groups;

  const ProductGroupsLoaded(this.groups);

  @override
  List<Object> get props => [groups];
}

class ProductGroupCreated extends ProductGroupsState {
  final int id;

  const ProductGroupCreated(this.id);

  @override
  List<Object> get props => [id];
}

class ProductGroupUpdated extends ProductGroupsState {}

class ProductGroupDeleted extends ProductGroupsState {}

class ProductGroupsError extends ProductGroupsState {
  final String message;

  const ProductGroupsError(this.message);

  @override
  List<Object> get props => [message];
}
