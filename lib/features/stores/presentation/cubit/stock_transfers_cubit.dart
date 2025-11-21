import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_transfer_repository.dart';

part 'stock_transfers_state.dart';

class StockTransfersCubit extends Cubit<StockTransfersState> {
  final StockTransferRepository repository;

  StockTransfersCubit(this.repository) : super(StockTransfersInitial());

  Future<void> loadTransfers() async {
    emit(StockTransfersLoading());
    final result = await repository.getTransfers();
    result.fold(
      (failure) => emit(StockTransfersError(failure.message)),
      (transfers) => emit(StockTransfersLoaded(transfers)),
    );
  }

  Future<void> loadTransfersByWarehouse(int warehouseId) async {
    emit(StockTransfersLoading());
    final result = await repository.getTransfersByWarehouse(warehouseId);
    result.fold(
      (failure) => emit(StockTransfersError(failure.message)),
      (transfers) => emit(StockTransfersLoaded(transfers)),
    );
  }

  Future<void> createTransfer(StockTransferEntity transfer) async {
    emit(StockTransfersLoading());
    final result = await repository.createTransfer(transfer);
    await result.fold(
      (failure) async => emit(StockTransfersError(failure.message)),
      (id) async {
        emit(TransferCreated(id));
        await loadTransfers();
      },
    );
  }

  Future<void> updateTransferStatus(int id, TransferStatus status) async {
    emit(StockTransfersLoading());
    final result = await repository.updateTransferStatus(id, status);
    await result.fold(
      (failure) async => emit(StockTransfersError(failure.message)),
      (_) async {
        emit(TransferStatusUpdated(id, status.name));
        await loadTransfers();
      },
    );
  }

  Future<void> deleteTransfer(int id) async {
    emit(StockTransfersLoading());
    final result = await repository.deleteTransfer(id);
    await result.fold(
      (failure) async => emit(StockTransfersError(failure.message)),
      (_) async {
        emit(TransferDeleted());
        await loadTransfers();
      },
    );
  }
}
