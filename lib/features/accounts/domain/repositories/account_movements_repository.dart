import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';

abstract class AccountMovementsRepository {
  Future<Either<Failure, List<AccountMovementEntity>>> getAccountMovements({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  });

  Future<Either<Failure, AccountMovementsSummary>> getAccountMovementsSummary({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
