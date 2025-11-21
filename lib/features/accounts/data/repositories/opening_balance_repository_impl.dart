import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/data/datasources/opening_balance_local_datasource.dart';
import 'package:muhasib/features/accounts/data/models/opening_balance_model.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/opening_balance_repository.dart';

class OpeningBalanceRepositoryImpl implements OpeningBalanceRepository {
  final OpeningBalanceLocalDataSource localDataSource;

  OpeningBalanceRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<OpeningBalanceEntity>>> getAllOpeningBalances() async {
    try {
      final openingBalances = await localDataSource.getAllOpeningBalances();
      return Right(openingBalances.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OpeningBalanceEntity>> getOpeningBalanceById(int id) async {
    try {
      final openingBalance = await localDataSource.getOpeningBalanceById(id);
      return Right(openingBalance.toEntity());
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createOpeningBalance(OpeningBalanceEntity openingBalance) async {
    try {
      final model = OpeningBalanceModel.fromEntity(openingBalance);
      final id = await localDataSource.createOpeningBalance(model);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOpeningBalance(OpeningBalanceEntity openingBalance) async {
    try {
      final model = OpeningBalanceModel.fromEntity(openingBalance);
      await localDataSource.updateOpeningBalance(model);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOpeningBalance(int id) async {
    try {
      await localDataSource.deleteOpeningBalance(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> postOpeningBalance(int id) async {
    try {
      await localDataSource.postOpeningBalance(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateNextNumber() async {
    try {
      final number = await localDataSource.generateNextNumber();
      return Right(number);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
