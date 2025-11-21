import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_sub_unit_repository.dart';

part 'product_sub_units_state.dart';

class ProductSubUnitsCubit extends Cubit<ProductSubUnitsState> {
  final ProductSubUnitRepository repository;

  ProductSubUnitsCubit(this.repository) : super(ProductSubUnitsInitial());

  Future<void> loadAllSubUnits() async {
    emit(ProductSubUnitsLoading());
    final result = await repository.getAllSubUnits();
    result.fold(
      (failure) => emit(ProductSubUnitsError(failure.message)),
      (subUnits) => emit(ProductSubUnitsLoaded(subUnits)),
    );
  }

  Future<void> loadSubUnitsByProduct(int categoryId) async {
    emit(ProductSubUnitsLoading());
    final result = await repository.getSubUnitsByProduct(categoryId);
    result.fold(
      (failure) => emit(ProductSubUnitsError(failure.message)),
      (subUnits) => emit(ProductSubUnitsLoaded(subUnits)),
    );
  }

  Future<void> createSubUnit(ProductSubUnitEntity subUnit) async {
    emit(ProductSubUnitsLoading());
    final result = await repository.createSubUnit(subUnit);
    await result.fold(
      (failure) async => emit(ProductSubUnitsError(failure.message)),
      (id) async {
        emit(ProductSubUnitCreated(id));
        if (subUnit.categoryId != null) {
          await loadSubUnitsByProduct(subUnit.categoryId!);
        } else {
          await loadAllSubUnits();
        }
      },
    );
  }

  Future<void> updateSubUnit(ProductSubUnitEntity subUnit) async {
    emit(ProductSubUnitsLoading());
    final result = await repository.updateSubUnit(subUnit);
    await result.fold(
      (failure) async => emit(ProductSubUnitsError(failure.message)),
      (_) async {
        emit(ProductSubUnitUpdated());
        if (subUnit.categoryId != null) {
          await loadSubUnitsByProduct(subUnit.categoryId!);
        } else {
          await loadAllSubUnits();
        }
      },
    );
  }

  Future<void> deleteSubUnit(int id) async {
    emit(ProductSubUnitsLoading());
    final result = await repository.deleteSubUnit(id);
    await result.fold(
      (failure) async => emit(ProductSubUnitsError(failure.message)),
      (_) async {
        emit(ProductSubUnitDeleted());
        await loadAllSubUnits();
      },
    );
  }

  Future<void> setMainUnit(int categoryId, int subUnitId) async {
    emit(ProductSubUnitsLoading());
    final result = await repository.setMainUnit(categoryId, subUnitId);
    await result.fold(
      (failure) async => emit(ProductSubUnitsError(failure.message)),
      (_) async {
        emit(ProductSubUnitMainSet());
        await loadSubUnitsByProduct(categoryId);
      },
    );
  }
}
