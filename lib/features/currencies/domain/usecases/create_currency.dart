import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class CreateCurrency implements Usecase<Either<Failure, int>, CurrencyEntity> {
  final CurrencyRepository repository;
  CreateCurrency(this.repository);

  @override
  Future<Either<Failure, int>> call({required CurrencyEntity params}) async {
    return await repository.createCurrency(params);
  }
}
