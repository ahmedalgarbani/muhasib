import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';

abstract class OpeningBalanceRepository {
  Future<Either<Failure, List<OpeningBalanceEntity>>> getAllOpeningBalances();
  Future<Either<Failure, OpeningBalanceEntity>> getOpeningBalanceById(int id);
  Future<Either<Failure, int>> createOpeningBalance(OpeningBalanceEntity openingBalance);
  Future<Either<Failure, void>> updateOpeningBalance(OpeningBalanceEntity openingBalance);
  Future<Either<Failure, void>> deleteOpeningBalance(int id);
  Future<Either<Failure, void>> postOpeningBalance(int id);
  Future<Either<Failure, String>> generateNextNumber();
}
