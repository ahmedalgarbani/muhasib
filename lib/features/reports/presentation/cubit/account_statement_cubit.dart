import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/account_statement_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_state.dart';

class AccountStatementCubit extends Cubit<AccountStatementState> {
  final AccountStatementRepository repository;
  ReportFilter? _currentFilter;
  int? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];

  AccountStatementCubit({required this.repository}) : super(AccountStatementInitial());

  Future<void> loadAccounts([int? initialAccountId]) async {
    final result = await repository.getAllAccounts();

    result.fold(
      (failure) {
        emit(AccountStatementError(message: failure.message));
      },
      (accounts) {
        _accounts = accounts;
        if (accounts.isEmpty) {
          emit(AccountStatementError(message: 'لا توجد حسابات مفعّلة'));
          return;
        }
        if (initialAccountId != null && accounts.any((a) => a['id'] == initialAccountId)) {
          _selectedAccountId = initialAccountId;
        } else if (_selectedAccountId == null || !accounts.any((a) => a['id'] == _selectedAccountId)) {
          _selectedAccountId = accounts.first['id'] as int;
        }
        // Preserve current filter (e.g. currentMonth from ReportBasePage) instead of empty.
        final filterToUse = _currentFilter ?? ReportFilter.currentMonth();
        _currentFilter = filterToUse;
        loadAccountStatement(_selectedAccountId!, filterToUse);
      },
    );
  }

  Future<void> loadAccountStatement(int accountId, [ReportFilter? filter]) async {
    emit(AccountStatementLoading(accounts: _accounts, selectedAccountId: _selectedAccountId));

    _selectedAccountId = accountId;
    _currentFilter = filter ?? _currentFilter ?? ReportFilter.currentMonth();

    final transactionsResult = await repository.getAccountStatement(
      accountId: accountId,
      filter: _currentFilter!,
    );
    
    final summaryResult = await repository.getAccountStatementSummary(
      accountId: accountId,
      filter: _currentFilter!,
    );

    transactionsResult.fold(
      (failure) {
        emit(AccountStatementError(message: failure.message));
      },
      (transactions) {
        summaryResult.fold(
          (failure) {
            emit(AccountStatementError(message: failure.message));
          },
          (summary) {
            emit(AccountStatementLoaded(
              transactions: transactions,
              summary: summary,
              accounts: _accounts,
              selectedAccountId: _selectedAccountId,
            ));
          },
        );
      },
    );
  }

  void selectAccount(int accountId) {
    if (_selectedAccountId != accountId) {
      loadAccountStatement(accountId, _currentFilter);
    }
  }

  void updateDateRange(ReportFilter filter) {
    _currentFilter = filter;
    if (_selectedAccountId != null) {
      loadAccountStatement(_selectedAccountId!, filter);
    }
    // If accounts not yet loaded, the pending filter will be used by loadAccounts().
  }

  void refresh() {
    if (_selectedAccountId != null) {
      loadAccountStatement(_selectedAccountId!, _currentFilter);
    } else {
      loadAccounts();
    }
  }
}
