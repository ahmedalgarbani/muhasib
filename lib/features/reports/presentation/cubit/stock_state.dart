import 'package:muhasib/features/reports/domain/entities/stock_entity.dart';

abstract class StockState {}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockEntity> stocks;
  final StockSummary summary;
  final String searchQuery;

  StockLoaded({
    required this.stocks,
    required this.summary,
    this.searchQuery = '',
  });

  List<StockEntity> get filteredStocks {
    if (searchQuery.isEmpty) {
      return stocks;
    }
    final query = searchQuery.toLowerCase();
    return stocks.where((stock) =>
      stock.productName.toLowerCase().contains(query) ||
      stock.productCode.toLowerCase().contains(query) ||
      (stock.categoryName?.toLowerCase().contains(query) ?? false)
    ).toList();
  }
}

class StockError extends StockState {
  final String message;

  StockError({required this.message});
}
