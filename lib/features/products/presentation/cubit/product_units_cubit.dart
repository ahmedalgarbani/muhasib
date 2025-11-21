import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_unit_repository.dart';

part 'product_units_state.dart';

class ProductUnitsCubit extends Cubit<ProductUnitsState> {
  final ProductUnitRepository repository;

  ProductUnitsCubit(this.repository) : super(ProductUnitsInitial());

  Future<void> loadAllUnits() async {
    emit(ProductUnitsLoading());
    final result = await repository.getAllUnits();
    result.fold(
      (failure) => emit(ProductUnitsError(failure.message)),
      (units) => emit(ProductUnitsLoaded(units)),
    );
  }

  Future<void> searchUnits(String query) async {
    emit(ProductUnitsLoading());
    final result = await repository.searchUnits(query);
    result.fold(
      (failure) => emit(ProductUnitsError(failure.message)),
      (units) => emit(ProductUnitsLoaded(units)),
    );
  }

  Future<void> createUnit(ProductUnitEntity unit) async {
    emit(ProductUnitsLoading());
    final result = await repository.createUnit(unit);
    await result.fold(
      (failure) async => emit(ProductUnitsError(failure.message)),
      (id) async {
        emit(ProductUnitCreated(id));
        await loadAllUnits();
      },
    );
  }

  Future<void> updateUnit(ProductUnitEntity unit) async {
    emit(ProductUnitsLoading());
    final result = await repository.updateUnit(unit);
    await result.fold(
      (failure) async => emit(ProductUnitsError(failure.message)),
      (_) async {
        emit(ProductUnitUpdated());
        await loadAllUnits();
      },
    );
  }

  Future<void> deleteUnit(int id) async {
    emit(ProductUnitsLoading());
    final result = await repository.deleteUnit(id);
    await result.fold(
      (failure) async => emit(ProductUnitsError(failure.message)),
      (_) async {
        emit(ProductUnitDeleted());
        await loadAllUnits();
      },
    );
  }
}
