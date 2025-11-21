part of 'stock_transfers_cubit.dart';

abstract class StockTransfersState extends Equatable {
  const StockTransfersState();

  @override
  List<Object> get props => [];
}

class StockTransfersInitial extends StockTransfersState {}

class StockTransfersLoading extends StockTransfersState {}

class StockTransfersLoaded extends StockTransfersState {
  final List<StockTransferEntity> transfers;

  const StockTransfersLoaded(this.transfers);

  @override
  List<Object> get props => [transfers];
}

class TransferCreated extends StockTransfersState {
  final int id;

  const TransferCreated(this.id);

  @override
  List<Object> get props => [id];
}

class TransferStatusUpdated extends StockTransfersState {
  final int id;
  final String status;

  const TransferStatusUpdated(this.id, this.status);

  @override
  List<Object> get props => [id, status];
}

class TransferDeleted extends StockTransfersState {}

class StockTransfersError extends StockTransfersState {
  final String message;

  const StockTransfersError(this.message);

  @override
  List<Object> get props => [message];
}
