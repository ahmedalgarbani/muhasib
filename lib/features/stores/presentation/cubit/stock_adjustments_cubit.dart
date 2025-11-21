import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_adjustment_repository.dart';

part 'stock_adjustments_state.dart';

class StockAdjustmentsCubit extends Cubit<StockAdjustmentsState> {
  final StockAdjustmentRepository repository;

  StockAdjustmentsCubit(this.repository) : super(StockAdjustmentsInitial());

  Future<void> loadAdjustments() async {
    emit(StockAdjustmentsLoading());
    final result = await repository.getAdjustments();
    result.fold(
      (failure) => emit(StockAdjustmentsError(failure.message)),
      (adjustments) => emit(StockAdjustmentsLoaded(adjustments)),
    );
  }

  Future<void> loadAdjustmentsByWarehouse(int warehouseId) async {
    emit(StockAdjustmentsLoading());
    final result = await repository.getAdjustmentsByWarehouse(warehouseId);
    result.fold(
      (failure) => emit(StockAdjustmentsError(failure.message)),
      (adjustments) => emit(StockAdjustmentsLoaded(adjustments)),
    );
  }

  Future<void> createAdjustment(StockAdjustmentEntity adjustment) async {
    emit(StockAdjustmentsLoading());
    final result = await repository.createAdjustment(adjustment);
    await result.fold(
      (failure) async => emit(StockAdjustmentsError(failure.message)),
      (id) async {
        emit(AdjustmentCreated(id));
        await loadAdjustments();
      },
    );
  }

  Future<void> postAdjustment(int id) async {
    emit(StockAdjustmentsLoading());
    final result = await repository.postAdjustment(id);
    await result.fold(
      (failure) async => emit(StockAdjustmentsError(failure.message)),
      (_) async {
        emit(AdjustmentPosted(id));
        await loadAdjustments();
      },
    );
  }

  Future<void> deleteAdjustment(int id) async {
    emit(StockAdjustmentsLoading());
    final result = await repository.deleteAdjustment(id);
    await result.fold(
      (failure) async => emit(StockAdjustmentsError(failure.message)),
      (_) async {
        emit(AdjustmentDeleted());
        await loadAdjustments();
      },
    );
  }
}
