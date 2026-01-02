import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_account_movements.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_movements_state.dart';

class AccountMovementsCubit extends Cubit<AccountMovementsState> {
  final GetAccountMovements getAccountMovements;
  final GetAccountMovementsSummary getAccountMovementsSummary;
  
  int? _currentAccountId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  AccountMovementsCubit({
    required this.getAccountMovements,
    required this.getAccountMovementsSummary,
  }) : super(AccountMovementsInitial());

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  Future<void> loadMovements(int accountId) async {
    _currentAccountId = accountId;
    emit(AccountMovementsLoading());

    final movementsResult = await getAccountMovements(
      accountId: accountId,
      startDate: _startDate,
      endDate: _endDate,
      limit: 100,
    );

    final summaryResult = await getAccountMovementsSummary(
      accountId: accountId,
      startDate: _startDate,
      endDate: _endDate,
    );

    movementsResult.fold(
      (failure) => emit(AccountMovementsError(message: failure.message)),
      (movements) {
        summaryResult.fold(
          (failure) => emit(AccountMovementsError(message: failure.message)),
          (summary) => emit(AccountMovementsLoaded(
            movements: movements,
            summary: summary,
            startDate: _startDate,
            endDate: _endDate,
          )),
        );
      },
    );
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    if (_currentAccountId != null) {
      loadMovements(_currentAccountId!);
    }
  }

  void refresh() {
    if (_currentAccountId != null) {
      loadMovements(_currentAccountId!);
    }
  }
}
