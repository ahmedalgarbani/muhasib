import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_validation_service.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_repository.dart';
import '../datasources/account_local_datasource.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountLocalDataSource localDataSource;
  final AccountValidationService? validationService;

  AccountRepositoryImpl(this.localDataSource, {this.validationService});

  @override
  Future<Either<Failure, List<AccountEntity>>> getAllAccounts() async {
    try {
      final accounts = await localDataSource.getAllAccounts();
      return Right(accounts.map((model) => model.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> getAccountById(int id) async {
    try {
      final account = await localDataSource.getAccountById(id);
      return Right(account.toEntity());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> getAccountByCId(int cId) async {
    try {
      final account = await localDataSource.getAccountByCId(cId);
      return Right(account.toEntity());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AccountEntity>>> getAccountsByType(
    int type,
  ) async {
    try {
      final accounts = await localDataSource.getAccountsByType(type);
      return Right(accounts.map((model) => model.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AccountEntity>>> getMasterAccounts() async {
    try {
      final accounts = await localDataSource.getMasterAccounts();
      return Right(accounts.map((model) => model.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AccountEntity>>> getSubAccounts(
    int masterId,
  ) async {
    try {
      final accounts = await localDataSource.getSubAccounts(masterId);
      return Right(accounts.map((model) => model.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createAccount(AccountEntity account) async {
    try {
      // Validate account type hierarchy if validation service is available
      if (validationService != null && account.masterId != null) {
        final hierarchyResult = await validationService!.validateAccountTypeHierarchy(
          parentId: account.masterId,
          accountType: account.type,
        );
        if (hierarchyResult.isLeft()) {
          return Left(hierarchyResult.fold((l) => l, (r) => UnknownFailure('')));
        }
      }
      
      final accountModel = AccountModel.fromEntity(account);
      final id = await localDataSource.insertAccount(accountModel);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> updateAccount(AccountEntity account) async {
    try {
      // Validate account type hierarchy if validation service is available
      if (validationService != null && account.masterId != null) {
        final hierarchyResult = await validationService!.validateAccountTypeHierarchy(
          parentId: account.masterId,
          accountType: account.type,
        );
        if (hierarchyResult.isLeft()) {
          return Left(hierarchyResult.fold((l) => l, (r) => UnknownFailure('')));
        }
      }
      
      final accountModel = AccountModel.fromEntity(account);
      final count = await localDataSource.updateAccount(accountModel);
      return Right(count);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteAccount(int id) async {
    try {
      // Validate deletion if validation service is available
      if (validationService != null) {
        final canDeleteResult = await validationService!.canDeleteAccount(id);
        if (canDeleteResult.isLeft()) {
          return Left(canDeleteResult.fold((l) => l, (r) => UnknownFailure('')));
        }
      }
      
      final count = await localDataSource.deleteAccount(id);
      return Right(count);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AccountEntity>>> searchAccounts(
    String query,
  ) async {
    try {
      final accounts = await localDataSource.searchAccounts(query);
      return Right(accounts.map((model) => model.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

