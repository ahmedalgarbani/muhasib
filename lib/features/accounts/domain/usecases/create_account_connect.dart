import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class CreateAccountConnect
    implements Usecase<Either<Failure, int>, AccountConnectEntity> {
  final AccountConnectRepository repository;

  CreateAccountConnect(this.repository);

  @override
  Future<Either<Failure, int>> call({
    required AccountConnectEntity params,
  }) async {
    return await repository.createAccountConnect(params);
  }
}
