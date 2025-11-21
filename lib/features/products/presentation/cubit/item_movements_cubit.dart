import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/products/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/products/domain/repositories/item_movement_repository.dart';

part 'item_movements_state.dart';

class ItemMovementsCubit extends Cubit<ItemMovementsState> {
  final ItemMovementRepository repository;

  ItemMovementsCubit(this.repository) : super(ItemMovementsInitial());

  Future<void> loadAllMovements() async {
    emit(ItemMovementsLoading());
    final result = await repository.getAllMovements();
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }

  Future<void> loadMovementsByProduct(int categoryId) async {
    emit(ItemMovementsLoading());
    final result = await repository.getMovementsByProduct(categoryId);
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }

  Future<void> loadMovementsByDateRange(DateTime startDate, DateTime endDate) async {
    emit(ItemMovementsLoading());
    final result = await repository.getMovementsByDateRange(startDate, endDate);
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }

  Future<void> loadMovementsByStock(int stockId) async {
    emit(ItemMovementsLoading());
    final result = await repository.getMovementsByStock(stockId);
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }

  Future<void> loadMovementsByType(int transDocType) async {
    emit(ItemMovementsLoading());
    final result = await repository.getMovementsByType(transDocType);
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }

  Future<void> searchMovements(String query) async {
    emit(ItemMovementsLoading());
    final result = await repository.searchMovements(query);
    result.fold(
      (failure) => emit(ItemMovementsError(failure.message)),
      (movements) => emit(ItemMovementsLoaded(movements)),
    );
  }
}
