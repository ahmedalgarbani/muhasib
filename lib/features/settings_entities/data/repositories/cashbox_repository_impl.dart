import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/data/datasources/cashbox_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/cashbox_model.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/cashbox_repository.dart';

class CashboxRepositoryImpl implements CashboxRepository {
  final CashboxLocalDataSource localDataSource;

  CashboxRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<CashboxEntity>>> getCashboxes() async {
    try {
      final cashboxes = await localDataSource.getCashboxes();
      return Right(cashboxes);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CashboxEntity>> getCashboxById(int id) async {
    try {
      final cashbox = await localDataSource.getCashboxById(id);
      return Right(cashbox);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CashboxEntity?>> getMainCashbox() async {
    try {
      final cashbox = await localDataSource.getMainCashbox();
      return Right(cashbox);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CashboxEntity>>> getActiveCashboxes() async {
    try {
      final cashboxes = await localDataSource.getActiveCashboxes();
      return Right(cashboxes);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createCashbox(CashboxEntity cashbox) async {
    try {
      final model = cashbox is CashboxModel ? cashbox : CashboxModel.fromEntity(cashbox);
      final id = await localDataSource.insertCashbox(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCashbox(CashboxEntity cashbox) async {
    try {
      final model = cashbox is CashboxModel ? cashbox : CashboxModel.fromEntity(cashbox);
      await localDataSource.updateCashbox(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCashbox(int id) async {
    try {
      await localDataSource.deleteCashbox(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainCashbox(int id) async {
    try {
      await localDataSource.setMainCashbox(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CashboxEntity>>> searchCashboxes(String query) async {
    try {
      final cashboxes = await localDataSource.searchCashboxes(query);
      return Right(cashboxes);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

