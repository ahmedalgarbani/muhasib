import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class GetCurrencyById implements Usecase<Either<Failure, CurrencyEntity>, int> {
  final CurrencyRepository repository;
  GetCurrencyById(this.repository);

  @override
  Future<Either<Failure, CurrencyEntity>> call({required int params}) async {
    return await repository.getCurrencyById(params);
  }
}
