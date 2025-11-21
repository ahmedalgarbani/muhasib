import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/repositories/warehouse_repository.dart';

part 'warehouses_state.dart';

class WarehousesCubit extends Cubit<WarehousesState> {
  final WarehouseRepository repository;

  WarehousesCubit(this.repository) : super(WarehousesInitial());

  Future<void> loadWarehouses() async {
    emit(WarehousesLoading());
    final result = await repository.getWarehouses();
    result.fold(
      (failure) => emit(WarehousesError(failure.message)),
      (warehouses) => emit(WarehousesLoaded(warehouses)),
    );
  }

  Future<void> loadActiveWarehouses() async {
    emit(WarehousesLoading());
    final result = await repository.getActiveWarehouses();
    result.fold(
      (failure) => emit(WarehousesError(failure.message)),
      (warehouses) => emit(WarehousesLoaded(warehouses)),
    );
  }

  Future<void> searchWarehouses(String query) async {
    emit(WarehousesLoading());
    final result = await repository.searchWarehouses(query);
    result.fold(
      (failure) => emit(WarehousesError(failure.message)),
      (warehouses) => emit(WarehousesLoaded(warehouses)),
    );
  }

  Future<void> createWarehouse(WarehouseEntity warehouse) async {
    emit(WarehousesLoading());
    final result = await repository.createWarehouse(warehouse);
    await result.fold(
      (failure) async => emit(WarehousesError(failure.message)),
      (id) async {
        emit(WarehouseCreated(id));
        await loadWarehouses();
      },
    );
  }

  Future<void> updateWarehouse(WarehouseEntity warehouse) async {
    emit(WarehousesLoading());
    final result = await repository.updateWarehouse(warehouse);
    await result.fold(
      (failure) async => emit(WarehousesError(failure.message)),
      (_) async {
        emit(WarehouseUpdated());
        await loadWarehouses();
      },
    );
  }

  Future<void> deleteWarehouse(int id) async {
    emit(WarehousesLoading());
    final result = await repository.deleteWarehouse(id);
    await result.fold(
      (failure) async => emit(WarehousesError(failure.message)),
      (_) async {
        emit(WarehouseDeleted());
        await loadWarehouses();
      },
    );
  }

  Future<void> setMainWarehouse(int id) async {
    emit(WarehousesLoading());
    final result = await repository.setMainWarehouse(id);
    await result.fold(
      (failure) async => emit(WarehousesError(failure.message)),
      (_) async {
        emit(MainWarehouseSet());
        await loadWarehouses();
      },
    );
  }
}
