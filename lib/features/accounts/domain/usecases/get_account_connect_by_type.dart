import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class GetAccountConnectByType
    implements Usecase<Either<Failure, AccountConnectEntity?>, int> {
  final AccountConnectRepository repository;

  GetAccountConnectByType(this.repository);

  @override
  Future<Either<Failure, AccountConnectEntity?>> call({
    required int params,
  }) async {
    return await repository.getAccountConnectByType(params);
  }
}
