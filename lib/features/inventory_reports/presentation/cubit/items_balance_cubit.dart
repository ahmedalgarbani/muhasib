import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/items_balance_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/items_balance_repository.dart';

part 'items_balance_state.dart';

class ItemsBalanceCubit extends Cubit<ItemsBalanceState> {
  final ItemsBalanceRepository repository;
  int? _warehouseId;
  String _searchQuery = '';

  ItemsBalanceCubit(this.repository) : super(ItemsBalanceInitial());

  Future<void> loadBalances({int? warehouseId, String? searchQuery}) async {
    _warehouseId = warehouseId ?? _warehouseId;
    if (searchQuery != null) _searchQuery = searchQuery;
    // Explicit clear when caller passes null warehouseId via filterByWarehouse
    emit(ItemsBalanceLoading());
    final result = await repository.getBalances(
      warehouseId: _warehouseId,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    result.fold(
      (failure) => emit(ItemsBalanceError(failure.message)),
      (list) {
        if (list.isEmpty) {
          emit(ItemsBalanceEmpty());
        } else {
          emit(ItemsBalanceLoaded(balances: list));
        }
      },
    );
  }

  void updateSearch(String query) {
    _searchQuery = query;
    loadBalances(warehouseId: _warehouseId, searchQuery: query);
  }

  void filterByWarehouse(int? warehouseId) {
    _warehouseId = warehouseId;
    loadBalances(warehouseId: warehouseId);
  }

  void refresh() => loadBalances(warehouseId: _warehouseId, searchQuery: _searchQuery);
}
