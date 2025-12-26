import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/income_statement_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';

class IncomeStatementCubit extends Cubit<IncomeStatementState> {
  final IncomeStatementRepository repository;
  ReportFilter? _currentFilter;

  IncomeStatementCubit({required this.repository}) : super(IncomeStatementInitial());

  Future<void> loadIncomeStatement([ReportFilter? filter]) async {
    emit(IncomeStatementLoading());

    _currentFilter = filter ?? ReportFilter();

    final dataResult = await repository.getIncomeStatementData(filter: _currentFilter!);
    final summaryResult = await repository.getIncomeStatementSummary(filter: _currentFilter!);

    dataResult.fold(
      (failure) {
        emit(IncomeStatementError(message: failure.message));
      },
      (categories) {
        summaryResult.fold(
          (failure) {
            emit(IncomeStatementError(message: failure.message));
          },
          (summary) {
            emit(IncomeStatementLoaded(
              categories: categories,
              summary: summary,
            ));
          },
        );
      },
    );
  }

  void updateDateRange(ReportFilter filter) {
    _currentFilter = filter;
    loadIncomeStatement(filter);
  }

  void refresh() {
    loadIncomeStatement(_currentFilter);
  }
}
