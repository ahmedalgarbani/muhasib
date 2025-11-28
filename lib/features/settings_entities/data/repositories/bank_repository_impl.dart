import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/data/datasources/bank_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/bank_model.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';

class BankRepositoryImpl implements BankRepository {
  final BankLocalDataSource localDataSource;

  BankRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<BankEntity>>> getBanks() async {
    try {
      final banks = await localDataSource.getBanks();
      return Right(banks);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankEntity>> getBankById(int id) async {
    try {
      final bank = await localDataSource.getBankById(id);
      return Right(bank);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BankEntity>>> getActiveBanks() async {
    try {
      final banks = await localDataSource.getActiveBanks();
      return Right(banks);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createBank(BankEntity bank) async {
    try {
      final model = bank is BankModel ? bank : BankModel.fromEntity(bank);
      final id = await localDataSource.insertBank(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBank(BankEntity bank) async {
    try {
      final model = bank is BankModel ? bank : BankModel.fromEntity(bank);
      await localDataSource.updateBank(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBank(int id) async {
    try {
      await localDataSource.deleteBank(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BankEntity>>> searchBanks(String query) async {
    try {
      final banks = await localDataSource.searchBanks(query);
      return Right(banks);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

