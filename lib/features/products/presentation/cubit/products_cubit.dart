import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductRepository repository;

  ProductsCubit(this.repository) : super(ProductsInitial());

  Future<void> loadProducts() async {
    emit(ProductsLoading());
    final result = await repository.getProducts();
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> loadProductsByGroup(int groupId) async {
    emit(ProductsLoading());
    final result = await repository.getProductsByGroup(groupId);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> searchProducts(String query) async {
    emit(ProductsLoading());
    final result = await repository.searchProducts(query);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> createProduct(ProductEntity product) async {
    emit(ProductsLoading());
    final result = await repository.createProduct(product);
    await result.fold(
      (failure) async => emit(ProductsError(failure.message)),
      (id) async {
        emit(ProductCreated(id));
        await loadProducts();
      },
    );
  }

  Future<void> updateProduct(ProductEntity product) async {
    emit(ProductsLoading());
    final result = await repository.updateProduct(product);
    await result.fold(
      (failure) async => emit(ProductsError(failure.message)),
      (_) async {
        emit(ProductUpdated());
        await loadProducts();
      },
    );
  }

  Future<void> deleteProduct(int id) async {
    emit(ProductsLoading());
    final result = await repository.deleteProduct(id);
    await result.fold(
      (failure) async => emit(ProductsError(failure.message)),
      (_) async {
        emit(ProductDeleted());
        await loadProducts();
      },
    );
  }
}
