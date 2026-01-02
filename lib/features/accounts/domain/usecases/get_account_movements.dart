import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_movements_repository.dart';

class GetAccountMovements {
  final AccountMovementsRepository repository;

  GetAccountMovements(this.repository);

  Future<Either<Failure, List<AccountMovementEntity>>> call({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) {
    return repository.getAccountMovements(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }
}

class GetAccountMovementsSummary {
  final AccountMovementsRepository repository;

  GetAccountMovementsSummary(this.repository);

  Future<Either<Failure, AccountMovementsSummary>> call({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getAccountMovementsSummary(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
