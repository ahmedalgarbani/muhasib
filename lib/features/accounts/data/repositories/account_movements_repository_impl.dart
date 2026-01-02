import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/data/datasources/account_movements_local_datasource.dart';
import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_movements_repository.dart';

class AccountMovementsRepositoryImpl implements AccountMovementsRepository {
  final AccountMovementsLocalDataSource localDataSource;

  AccountMovementsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AccountMovementEntity>>> getAccountMovements({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    try {
      final movements = await localDataSource.getAccountMovements(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      return Right(movements);
    } catch (e) {
      return Left(CacheFailure('فشل في جلب حركات الحساب: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountMovementsSummary>> getAccountMovementsSummary({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final summary = await localDataSource.getAccountMovementsSummary(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(summary);
    } catch (e) {
      return Left(CacheFailure('فشل في جلب ملخص الحساب: ${e.toString()}'));
    }
  }
}
