import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class DeleteAccountConnect implements Usecase<Either<Failure, void>, int> {
  final AccountConnectRepository repository;

  DeleteAccountConnect(this.repository);

  @override
  Future<Either<Failure, void>> call({required int params}) async {
    return await repository.deleteAccountConnect(params);
  }
}
