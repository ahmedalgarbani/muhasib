import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class GetCurrencyByCode
    implements Usecase<Either<Failure, CurrencyEntity>, String> {
  final CurrencyRepository repository;
  GetCurrencyByCode(this.repository);

  @override
  Future<Either<Failure, CurrencyEntity>> call({required String params}) async {
    return await repository.getCurrencyByCode(params);
  }
}
