import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/item_movement_repository.dart';

part 'item_movement_state.dart';

class ItemMovementCubit extends Cubit<ItemMovementState> {
  final ItemMovementRepository repository;
  int? _warehouseId;
  String _searchQuery = '';

  ItemMovementCubit(this.repository) : super(ItemMovementInitial());

  Future<void> loadMovements({int? warehouseId, String? searchQuery}) async {
    if (warehouseId != null) _warehouseId = warehouseId;
    if (searchQuery != null) _searchQuery = searchQuery;
    // Explicit null handling for clearing warehouse filter
    if (warehouseId == null && searchQuery == null && state is! ItemMovementInitial) {
      // keep existing _warehouseId unless explicitly cleared via clearWarehouseFilter
    }
    emit(ItemMovementLoading());
    final result = await repository.getMovements(
      warehouseId: _warehouseId,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 500,
    );
    result.fold(
      (failure) => emit(ItemMovementError(failure.message)),
      (list) {
        if (list.isEmpty) {
          emit(ItemMovementEmpty());
        } else {
          emit(ItemMovementLoaded(movements: list));
        }
      },
    );
  }

  void updateSearch(String query) {
    _searchQuery = query;
    loadMovements(warehouseId: _warehouseId, searchQuery: _searchQuery);
  }

  void filterByWarehouse(int? warehouseId) {
    _warehouseId = warehouseId;
    loadMovements(warehouseId: warehouseId, searchQuery: _searchQuery);
  }

  void clearWarehouseFilter() {
    _warehouseId = null;
    loadMovements(warehouseId: null, searchQuery: _searchQuery);
  }

  void refresh() => loadMovements(warehouseId: _warehouseId, searchQuery: _searchQuery);
}
