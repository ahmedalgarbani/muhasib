import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';

abstract class IncomeStatementState {}

class IncomeStatementInitial extends IncomeStatementState {}

class IncomeStatementLoading extends IncomeStatementState {}

class IncomeStatementLoaded extends IncomeStatementState {
  final List<IncomeStatementEntity> categories;
  final IncomeStatementSummary summary;

  IncomeStatementLoaded({
    required this.categories,
    required this.summary,
  });
}

class IncomeStatementError extends IncomeStatementState {
  final String message;

  IncomeStatementError({required this.message});
}
