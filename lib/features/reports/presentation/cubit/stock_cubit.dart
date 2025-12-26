import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/repositories/stock_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_state.dart';

class StockCubit extends Cubit<StockState> {
  final StockRepository repository;
  int? _warehouseId;
  String? _categoryId;

  StockCubit({required this.repository}) : super(StockInitial());

  Future<void> loadStock({
    int? warehouseId,
    String? categoryId,
  }) async {
    emit(StockLoading());

    _warehouseId = warehouseId;
    _categoryId = categoryId;

    final stocksResult = await repository.getStockReport(
      warehouseId: _warehouseId,
      categoryId: _categoryId,
    );
    
    final summaryResult = await repository.getStockSummary(
      warehouseId: _warehouseId,
    );

    stocksResult.fold(
      (failure) {
        emit(StockError(message: failure.message));
      },
      (stocks) {
        summaryResult.fold(
          (failure) {
            emit(StockError(message: failure.message));
          },
          (summary) {
            emit(StockLoaded(
              stocks: stocks,
              summary: summary,
            ));
          },
        );
      },
    );
  }

  void updateSearch(String query) {
    if (state is StockLoaded) {
      final currentState = state as StockLoaded;
      emit(StockLoaded(
        stocks: currentState.stocks,
        summary: currentState.summary,
        searchQuery: query,
      ));
    }
  }

  void filterByWarehouse(int? warehouseId) {
    _warehouseId = warehouseId;
    loadStock(warehouseId: _warehouseId, categoryId: _categoryId);
  }

  void filterByCategory(String? categoryId) {
    _categoryId = categoryId;
    loadStock(warehouseId: _warehouseId, categoryId: _categoryId);
  }

  void refresh() {
    loadStock(warehouseId: _warehouseId, categoryId: _categoryId);
  }
}
