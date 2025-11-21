import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import '../entities/account_entity.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<AccountEntity>>> getAllAccounts();
  Future<Either<Failure, AccountEntity>> getAccountById(int id);
  Future<Either<Failure, AccountEntity>> getAccountByCId(int cId);
  Future<Either<Failure, List<AccountEntity>>> getAccountsByType(int type);
  Future<Either<Failure, List<AccountEntity>>> getMasterAccounts();
  Future<Either<Failure, List<AccountEntity>>> getSubAccounts(int masterId);
  Future<Either<Failure, int>> createAccount(AccountEntity account);
  Future<Either<Failure, int>> updateAccount(AccountEntity account);
  Future<Either<Failure, int>> deleteAccount(int id);
  Future<Either<Failure, List<AccountEntity>>> searchAccounts(String query);
}
