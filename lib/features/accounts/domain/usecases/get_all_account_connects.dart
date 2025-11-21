import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class GetAllAccountConnects
    implements Usecase<Either<Failure, List<AccountConnectEntity>>, NoParams> {
  final AccountConnectRepository repository;

  GetAllAccountConnects(this.repository);

  @override
  Future<Either<Failure, List<AccountConnectEntity>>> call({
    required NoParams params,
  }) async {
    return await repository.getAllAccountConnects();
  }
}
