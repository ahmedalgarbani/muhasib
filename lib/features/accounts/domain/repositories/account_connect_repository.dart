import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';

abstract class AccountConnectRepository {
  Future<Either<Failure, List<AccountConnectEntity>>> getAllAccountConnects();
  Future<Either<Failure, AccountConnectEntity>> getAccountConnectById(int id);
  Future<Either<Failure, int>> createAccountConnect(
    AccountConnectEntity accountConnect,
  );
  Future<Either<Failure, void>> updateAccountConnect(
    AccountConnectEntity accountConnect,
  );
  Future<Either<Failure, void>> deleteAccountConnect(int id);
  Future<Either<Failure, AccountConnectEntity?>> getAccountConnectByType(
    int type,
  );
}
