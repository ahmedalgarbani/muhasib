import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class SearchCurrencies
    implements Usecase<Either<Failure, List<CurrencyEntity>>, String> {
  final CurrencyRepository repository;
  SearchCurrencies(this.repository);

  @override
  Future<Either<Failure, List<CurrencyEntity>>> call({
    required String params,
  }) async {
    return await repository.searchCurrencies(params);
  }
}
