import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class UpdateAccountConnect
    implements Usecase<Either<Failure, void>, AccountConnectEntity> {
  final AccountConnectRepository repository;

  UpdateAccountConnect(this.repository);

  @override
  Future<Either<Failure, void>> call({
    required AccountConnectEntity params,
  }) async {
    return await repository.updateAccountConnect(params);
  }
}
