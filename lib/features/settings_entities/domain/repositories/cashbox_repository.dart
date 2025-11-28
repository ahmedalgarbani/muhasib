import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';

abstract class CashboxRepository {
  Future<Either<Failure, List<CashboxEntity>>> getCashboxes();
  Future<Either<Failure, CashboxEntity>> getCashboxById(int id);
  Future<Either<Failure, CashboxEntity?>> getMainCashbox();
  Future<Either<Failure, List<CashboxEntity>>> getActiveCashboxes();
  Future<Either<Failure, int>> createCashbox(CashboxEntity cashbox);
  Future<Either<Failure, void>> updateCashbox(CashboxEntity cashbox);
  Future<Either<Failure, void>> deleteCashbox(int id);
  Future<Either<Failure, void>> setMainCashbox(int id);
  Future<Either<Failure, List<CashboxEntity>>> searchCashboxes(String query);
}

