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
        if (initialAccountId != null && accounts.any((a) => a['id'] == initialAccountId)) {
          _selectedAccountId = initialAccountId;
        } else if (accounts.isNotEmpty && _selectedAccountId == null) {
          _selectedAccountId = accounts.first['id'] as int;
        }
        if (_selectedAccountId != null) {
          loadAccountStatement(_selectedAccountId!);
        }
      },
    );
  }

  Future<void> loadAccountStatement(int accountId, [ReportFilter? filter]) async {
    emit(AccountStatementLoading());

    _selectedAccountId = accountId;
    _currentFilter = filter ?? ReportFilter();

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
    if (_selectedAccountId != null) {
      _currentFilter = filter;
      loadAccountStatement(_selectedAccountId!, filter);
    }
  }

  void refresh() {
    if (_selectedAccountId != null) {
      loadAccountStatement(_selectedAccountId!, _currentFilter);
    } else {
      loadAccounts();
    }
  }
}
