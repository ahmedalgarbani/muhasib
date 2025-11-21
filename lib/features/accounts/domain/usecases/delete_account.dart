import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../repositories/account_repository.dart';

class DeleteAccount implements Usecase<Either<Failure, int>, int> {
  final AccountRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, int>> call({required int params}) async {
    return await repository.deleteAccount(params);
  }
}
