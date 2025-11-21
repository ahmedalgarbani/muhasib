import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/account_entity.dart';
import '../repositories/account_repository.dart';

class UpdateAccount implements Usecase<Either<Failure, int>, AccountEntity> {
  final AccountRepository repository;

  UpdateAccount(this.repository);

  @override
  Future<Either<Failure, int>> call({required AccountEntity params}) async {
    return await repository.updateAccount(params);
  }
}
