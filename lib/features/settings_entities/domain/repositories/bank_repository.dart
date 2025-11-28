import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';

abstract class BankRepository {
  Future<Either<Failure, List<BankEntity>>> getBanks();
  Future<Either<Failure, BankEntity>> getBankById(int id);
  Future<Either<Failure, List<BankEntity>>> getActiveBanks();
  Future<Either<Failure, int>> createBank(BankEntity bank);
  Future<Either<Failure, void>> updateBank(BankEntity bank);
  Future<Either<Failure, void>> deleteBank(int id);
  Future<Either<Failure, List<BankEntity>>> searchBanks(String query);
}

