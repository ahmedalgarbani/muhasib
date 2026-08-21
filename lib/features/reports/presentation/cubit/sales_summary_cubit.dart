import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/sales_summary_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_state.dart';

class SalesSummaryCubit extends Cubit<SalesSummaryState> {
  final SalesSummaryRepository repository;
  ReportFilter? _currentFilter;

  SalesSummaryCubit({required this.repository}) : super(SalesSummaryInitial());

  Future<void> loadSalesSummary([ReportFilter? filter]) async {
    emit(SalesSummaryLoading());

    _currentFilter = filter ?? _currentFilter ?? ReportFilter.currentMonth();

    final result = await repository.getSalesSummary(filter: _currentFilter!);

    result.fold(
      (failure) {
        emit(SalesSummaryError(message: failure.message));
      },
      (summary) {
        emit(SalesSummaryLoaded(summary: summary));
      },
    );
  }

  void updateDateRange(ReportFilter filter) {
    _currentFilter = filter;
    loadSalesSummary(filter);
  }

  void refresh() {
    loadSalesSummary(_currentFilter);
  }
}
