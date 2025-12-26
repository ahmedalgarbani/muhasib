import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';

abstract class TrialBalanceState {}

class TrialBalanceInitial extends TrialBalanceState {}

class TrialBalanceLoading extends TrialBalanceState {}

class TrialBalanceLoaded extends TrialBalanceState {
  final List<TrialBalanceEntity> accounts;
  final TrialBalanceSummary summary;

  TrialBalanceLoaded({
    required this.accounts,
    required this.summary,
  });
}

class TrialBalanceError extends TrialBalanceState {
  final String message;

  TrialBalanceError({required this.message});
}
