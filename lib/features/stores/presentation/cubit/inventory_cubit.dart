import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/repositories/inventory_repository.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository repository;

  InventoryCubit(this.repository) : super(InventoryInitial());

  Future<void> loadInventories() async {
    emit(InventoryLoading());
    final result = await repository.getInventories();
    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (inventories) => emit(InventoryLoaded(inventories)),
    );
  }

  Future<void> loadInventoriesByWarehouse(int warehouseId) async {
    emit(InventoryLoading());
    final result = await repository.getInventoriesByWarehouse(warehouseId);
    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (inventories) => emit(InventoryLoaded(inventories)),
    );
  }

  Future<void> createInventory(InventoryEntity inventory) async {
    emit(InventoryLoading());
    final result = await repository.createInventory(inventory);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (id) async {
        emit(InventoryCreated(id));
        await loadInventories();
      },
    );
  }

  Future<void> updateInventory(InventoryEntity inventory) async {
    emit(InventoryLoading());
    final result = await repository.updateInventory(inventory);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        emit(InventoryUpdated());
        await loadInventories();
      },
    );
  }

  Future<void> postInventory(int id) async {
    emit(InventoryLoading());
    final result = await repository.postInventory(id);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        emit(InventoryPosted(id));
        await loadInventories();
      },
    );
  }

  Future<void> deleteInventory(int id) async {
    emit(InventoryLoading());
    final result = await repository.deleteInventory(id);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        emit(InventoryDeleted());
        await loadInventories();
      },
    );
  }
}
