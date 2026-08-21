import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/product_price_report_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/product_price_report_repository.dart';

part 'product_price_report_state.dart';

class ProductPriceReportCubit extends Cubit<ProductPriceReportState> {
  final ProductPriceReportRepository repository;
  List<int> _selectedIds = [];
  String _searchQuery = '';

  ProductPriceReportCubit(this.repository) : super(ProductPriceReportInitial());

  Future<void> loadPrices({List<int>? productIds, String? searchQuery}) async {
    emit(ProductPriceReportLoading());
    if (productIds != null) _selectedIds = productIds;
    if (searchQuery != null) _searchQuery = searchQuery;
    final result = await repository.getPrices(
      productIds: _selectedIds.isEmpty ? null : _selectedIds,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    result.fold(
      (f) => emit(ProductPriceReportError(f.message)),
      (list) {
        if (list.isEmpty) {
          emit(ProductPriceReportEmpty());
        } else {
          emit(ProductPriceReportLoaded(prices: list, selectedIds: _selectedIds));
        }
      },
    );
  }

  void setSelectedIds(List<int> ids) {
    _selectedIds = ids;
    loadPrices(productIds: ids);
  }

  void updateSearch(String query) {
    _searchQuery = query;
    loadPrices(searchQuery: query);
  }

  void refresh() => loadPrices(productIds: _selectedIds);
}
