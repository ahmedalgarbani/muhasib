import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/trial_balance_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_state.dart';

class TrialBalanceCubit extends Cubit<TrialBalanceState> {
  final TrialBalanceRepository repository;
  ReportFilter? _currentFilter;

  TrialBalanceCubit({required this.repository}) : super(TrialBalanceInitial());

  Future<void> loadTrialBalance([ReportFilter? filter]) async {
    emit(TrialBalanceLoading());

    _currentFilter = filter ?? _currentFilter ?? ReportFilter.currentMonth();

    final accountsResult = await repository.getTrialBalance(filter: _currentFilter!);
    final summaryResult = await repository.getTrialBalanceSummary(filter: _currentFilter!);

    accountsResult.fold(
      (failure) {
        emit(TrialBalanceError(message: failure.message));
      },
      (accounts) {
        summaryResult.fold(
          (failure) {
            emit(TrialBalanceError(message: failure.message));
          },
          (summary) {
            emit(TrialBalanceLoaded(
              accounts: accounts,
              summary: summary,
            ));
          },
        );
      },
    );
  }

  void updateDateRange(ReportFilter filter) {
    _currentFilter = filter;
    loadTrialBalance(filter);
  }

  void refresh() {
    loadTrialBalance(_currentFilter);
  }
}
