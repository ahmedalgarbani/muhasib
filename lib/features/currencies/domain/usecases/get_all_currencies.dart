import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class GetAllCurrencies
    implements Usecase<Either<Failure, List<CurrencyEntity>>, NoParams> {
  final CurrencyRepository repository;
  GetAllCurrencies(this.repository);

  @override
  Future<Either<Failure, List<CurrencyEntity>>> call({
    required NoParams params,
  }) async {
    return await repository.getAllCurrencies();
  }
}
