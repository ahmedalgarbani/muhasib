part of 'stock_adjustments_cubit.dart';

abstract class StockAdjustmentsState extends Equatable {
  const StockAdjustmentsState();

  @override
  List<Object> get props => [];
}

class StockAdjustmentsInitial extends StockAdjustmentsState {}

class StockAdjustmentsLoading extends StockAdjustmentsState {}

class StockAdjustmentsLoaded extends StockAdjustmentsState {
  final List<StockAdjustmentEntity> adjustments;

  const StockAdjustmentsLoaded(this.adjustments);

  @override
  List<Object> get props => [adjustments];
}

class AdjustmentCreated extends StockAdjustmentsState {
  final int id;

  const AdjustmentCreated(this.id);

  @override
  List<Object> get props => [id];
}

class AdjustmentPosted extends StockAdjustmentsState {
  final int id;

  const AdjustmentPosted(this.id);

  @override
  List<Object> get props => [id];
}

class AdjustmentDeleted extends StockAdjustmentsState {}

class StockAdjustmentsError extends StockAdjustmentsState {
  final String message;

  const StockAdjustmentsError(this.message);

  @override
  List<Object> get props => [message];
}
