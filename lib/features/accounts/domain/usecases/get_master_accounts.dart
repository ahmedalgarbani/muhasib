import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/account_entity.dart';
import '../repositories/account_repository.dart';

class GetMasterAccounts
    implements Usecase<Either<Failure, List<AccountEntity>>, NoParams> {
  final AccountRepository repository;

  GetMasterAccounts(this.repository);

  @override
  Future<Either<Failure, List<AccountEntity>>> call({
    required NoParams params,
  }) async {
    return await repository.getMasterAccounts();
  }
}
