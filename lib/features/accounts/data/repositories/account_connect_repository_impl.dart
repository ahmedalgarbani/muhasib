import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/data/datasources/account_connect_local_datasource.dart';
import 'package:muhasib/features/accounts/data/models/account_connect_model.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

class AccountConnectRepositoryImpl implements AccountConnectRepository {
  final AccountConnectLocalDataSource localDataSource;

  AccountConnectRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AccountConnectEntity>>>
  getAllAccountConnects() async {
    try {
      final accountConnects = await localDataSource.getAllAccountConnects();

      final List<AccountConnectEntity> entities = accountConnects
          .map<AccountConnectEntity>((e) => e.toEntity(e))
          .toList();

      return Right(entities);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountConnectEntity>> getAccountConnectById(
    int id,
  ) async {
    try {
      final accountConnect = await localDataSource.getAccountConnectById(id);
      return Right(accountConnect);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createAccountConnect(
    AccountConnectEntity accountConnect,
  ) async {
    try {
      final model = AccountConnectModel.fromEntity(accountConnect);
      final id = await localDataSource.createAccountConnect(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAccountConnect(
    AccountConnectEntity accountConnect,
  ) async {
    try {
      final model = AccountConnectModel.fromEntity(accountConnect);
      await localDataSource.updateAccountConnect(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccountConnect(int id) async {
    try {
      await localDataSource.deleteAccountConnect(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountConnectEntity?>> getAccountConnectByType(
    int type,
  ) async {
    try {
      final accountConnect = await localDataSource.getAccountConnectByType(
        type,
      );
      return Right(accountConnect);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
