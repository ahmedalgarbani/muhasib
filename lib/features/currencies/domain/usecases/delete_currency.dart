import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class DeleteCurrency implements Usecase<Either<Failure, int>, int> {
  final CurrencyRepository repository;
  DeleteCurrency(this.repository);

  @override
  Future<Either<Failure, int>> call({required int params}) async {
    return await repository.deleteCurrency(params);
  }
}
