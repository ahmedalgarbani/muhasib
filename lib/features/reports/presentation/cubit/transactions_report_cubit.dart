import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/transactions_report_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_state.dart';

class TransactionsReportCubit extends Cubit<TransactionsReportState> {
  final TransactionsReportRepository _repository;

  TransactionsReportCubit(this._repository) : super(TransactionsReportInitial());

  ReportFilter _currentFilter = ReportFilter.currentMonth();
  String _selectedType = 'all';
  String _sortBy = 'date';
  bool _isAscending = false;

  Future<void> loadTransactions({
    ReportFilter? filter,
    String? transactionType,
    String? sortBy,
    bool? isAscending,
  }) async {
    emit(TransactionsReportLoading());

    // Update internal state
    if (filter != null) _currentFilter = filter;
    if (transactionType != null) _selectedType = transactionType;
    if (sortBy != null) _sortBy = sortBy;
    if (isAscending != null) _isAscending = isAscending;

    // Get transactions
    final transactionsResult = await _repository.getTransactions(
      filter: _currentFilter,
      transactionType: _selectedType == 'all' ? null : _selectedType,
      sortBy: _sortBy,
      isAscending: _isAscending,
    );

    // Get summary
    final summaryResult = await _repository.getTransactionsSummary(
      filter: _currentFilter,
      transactionType: _selectedType == 'all' ? null : _selectedType,
    );

    transactionsResult.fold(
      (failure) => emit(TransactionsReportError(message: failure.message)),
      (transactions) {
        summaryResult.fold(
          (failure) => emit(TransactionsReportError(message: failure.message)),
          (summary) => emit(TransactionsReportLoaded(
            transactions: transactions,
            summary: summary,
            selectedType: _selectedType,
            sortBy: _sortBy,
            isAscending: _isAscending,
          )),
        );
      },
    );
  }

  Future<void> changeFilter(String transactionType) async {
    if (state is TransactionsReportLoaded) {
      final currentState = state as TransactionsReportLoaded;
      
      // Only reload if the type actually changed
      if (transactionType != currentState.selectedType) {
        await loadTransactions(transactionType: transactionType);
      }
    } else {
      await loadTransactions(transactionType: transactionType);
    }
  }

  Future<void> changeSort(String sortBy) async {
    if (state is TransactionsReportLoaded) {
      final currentState = state as TransactionsReportLoaded;
      
      // Only reload if the sort actually changed
      if (sortBy != currentState.sortBy) {
        await loadTransactions(sortBy: sortBy);
      }
    } else {
      await loadTransactions(sortBy: sortBy);
    }
  }

  Future<void> toggleSortDirection() async {
    _isAscending = !_isAscending;
    await loadTransactions(isAscending: _isAscending);
  }

  Future<void> updateDateRange(ReportFilter filter) async {
    await loadTransactions(filter: filter);
  }

  Future<void> searchTransactions(String query) async {
    if (state is TransactionsReportLoaded) {
      final currentState = state as TransactionsReportLoaded;
      
      if (query.isEmpty) {
        // If query is empty, reload original transactions
        await loadTransactions();
        return;
      }

      emit(TransactionsReportSearching(
        previousTransactions: currentState.transactions,
      ));

      final result = await _repository.searchTransactions(
        query: query,
        filter: _currentFilter,
      );

      result.fold(
        (failure) => emit(TransactionsReportError(message: failure.message)),
        (transactions) {
          // Calculate summary for searched transactions
          double totalDebit = 0;
          double totalCredit = 0;
          
          for (final transaction in transactions) {
            for (final detail in transaction.details) {
              totalDebit += detail.debitAmount;
              totalCredit += detail.creditAmount;
            }
          }

          emit(TransactionsReportLoaded(
            transactions: transactions,
            summary: {
              'count': transactions.length,
              'totalDebit': totalDebit,
              'totalCredit': totalCredit,
            },
            selectedType: currentState.selectedType,
            sortBy: currentState.sortBy,
            isAscending: currentState.isAscending,
          ));
        },
      );
    } else {
      await loadTransactions();
    }
  }

  Future<void> refreshTransactions() async {
    await loadTransactions();
  }

  Future<void> exportToPdf() async {
    if (state is TransactionsReportLoaded) {
      // TODO: Implement PDF export
      // This would typically involve creating a PDF document with the transactions
      // and saving it or sharing it
    }
  }

  Future<void> exportToExcel() async {
    if (state is TransactionsReportLoaded) {
      // TODO: Implement Excel export
      // This would typically involve creating an Excel file with the transactions
      // and saving it or sharing it
    }
  }

  Future<void> printReport() async {
    if (state is TransactionsReportLoaded) {
      // TODO: Implement print functionality
      // This would typically involve creating a printable version of the report
      // and sending it to the printer
    }
  }
}
