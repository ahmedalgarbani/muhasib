import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/currency_validation_service.dart';
import 'package:muhasib/features/currencies/data/datasources/currency_local_datasource.dart';
import 'package:muhasib/features/currencies/data/models/currency_model.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final CurrencyLocalDataSource localDataSource;
  final CurrencyValidationService? validationService;

  CurrencyRepositoryImpl(this.localDataSource, {this.validationService});

  @override
  Future<Either<Failure, List<CurrencyEntity>>> getAllCurrencies() async {
    try {
      final items = await localDataSource.getAllCurrencies();
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CurrencyEntity>> getCurrencyById(int id) async {
    try {
      final item = await localDataSource.getCurrencyById(id);
      return Right(item.toEntity());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CurrencyEntity>> getCurrencyByCode(String code) async {
    try {
      final item = await localDataSource.getCurrencyByCode(code);
      return Right(item.toEntity());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createCurrency(CurrencyEntity currency) async {
    try {
      final model = CurrencyModel.fromEntity(currency);
      final id = await localDataSource.insertCurrency(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> updateCurrency(CurrencyEntity currency) async {
    try {
      // Validate modification if validation service is available
      if (validationService != null && currency.id != null) {
        // Check if trying to change local currency status
        final existingCurrency = await localDataSource.getCurrencyById(currency.id!);
        final isChangingLocalStatus = existingCurrency.isLocalCurrency != currency.isLocalCurrency;
        
        final validationError = await validationService!.canModifyCurrency(
          currency.id!,
          isChangingLocalStatus: isChangingLocalStatus,
        );
        if (validationError != null) {
          return Left(ValidationFailure(message: validationError));
        }
      }
      
      final model = CurrencyModel.fromEntity(currency);
      final count = await localDataSource.updateCurrency(model);
      return Right(count);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteCurrency(int id) async {
    try {
      // Validate deletion if validation service is available
      if (validationService != null) {
        final validationError = await validationService!.canDeleteCurrency(id);
        if (validationError != null) {
          return Left(ValidationFailure(message: validationError));
        }
      }
      
      final count = await localDataSource.deleteCurrency(id);
      return Right(count);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CurrencyEntity>>> searchCurrencies(
    String query,
  ) async {
    try {
      final items = await localDataSource.searchCurrencies(query);
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

