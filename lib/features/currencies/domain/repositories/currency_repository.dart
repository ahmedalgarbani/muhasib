import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';

abstract class CurrencyRepository {
  Future<Either<Failure, List<CurrencyEntity>>> getAllCurrencies();
  Future<Either<Failure, CurrencyEntity>> getCurrencyById(int id);
  Future<Either<Failure, CurrencyEntity>> getCurrencyByCode(String code);
  Future<Either<Failure, int>> createCurrency(CurrencyEntity currency);
  Future<Either<Failure, int>> updateCurrency(CurrencyEntity currency);
  Future<Either<Failure, int>> deleteCurrency(int id);
  Future<Either<Failure, List<CurrencyEntity>>> searchCurrencies(String query);
}
