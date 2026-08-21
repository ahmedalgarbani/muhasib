part of 'product_price_report_cubit.dart';

abstract class ProductPriceReportState extends Equatable {
  const ProductPriceReportState();
  @override
  List<Object?> get props => [];
}

class ProductPriceReportInitial extends ProductPriceReportState {}

class ProductPriceReportLoading extends ProductPriceReportState {}

class ProductPriceReportLoaded extends ProductPriceReportState {
  final List<ProductPriceReportEntity> prices;
  final List<int> selectedIds;
  const ProductPriceReportLoaded({required this.prices, this.selectedIds = const []});
  @override
  List<Object?> get props => [prices, selectedIds];
}

class ProductPriceReportEmpty extends ProductPriceReportState {}

class ProductPriceReportError extends ProductPriceReportState {
  final String message;
  const ProductPriceReportError(this.message);
  @override
  List<Object?> get props => [message];
}
