import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/account_entity.dart';
import '../repositories/account_repository.dart';

class SearchAccounts
    implements Usecase<Either<Failure, List<AccountEntity>>, String> {
  final AccountRepository repository;

  SearchAccounts(this.repository);

  @override
  Future<Either<Failure, List<AccountEntity>>> call({
    required String params,
  }) async {
    return await repository.searchAccounts(params);
  }
}
