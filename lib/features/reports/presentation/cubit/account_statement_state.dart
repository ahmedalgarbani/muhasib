import 'package:muhasib/features/reports/domain/entities/account_statement_entity.dart';

abstract class AccountStatementState {}

class AccountStatementInitial extends AccountStatementState {}

class AccountStatementLoading extends AccountStatementState {
  final List<Map<String, dynamic>> accounts;
  final int? selectedAccountId;
  AccountStatementLoading({this.accounts = const [], this.selectedAccountId});
}

class AccountStatementLoaded extends AccountStatementState {
  final List<AccountStatementEntity> transactions;
  final AccountStatementSummary summary;
  final List<Map<String, dynamic>> accounts;
  final int? selectedAccountId;

  AccountStatementLoaded({
    required this.transactions,
    required this.summary,
    required this.accounts,
    this.selectedAccountId,
  });
}

class AccountStatementError extends AccountStatementState {
  final String message;

  AccountStatementError({required this.message});
}
