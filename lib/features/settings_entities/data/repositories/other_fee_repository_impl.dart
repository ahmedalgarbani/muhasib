import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/data/datasources/other_fee_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/other_fee_model.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/other_fee_repository.dart';

class OtherFeeRepositoryImpl implements OtherFeeRepository {
  final OtherFeeLocalDataSource localDataSource;

  OtherFeeRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<OtherFeeEntity>>> getOtherFees() async {
    try {
      final otherFees = await localDataSource.getOtherFees();
      return Right(otherFees);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, OtherFeeEntity>> getOtherFeeById(int id) async {
    try {
      final otherFee = await localDataSource.getOtherFeeById(id);
      return Right(otherFee);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OtherFeeEntity>>> getActiveOtherFees() async {
    try {
      final otherFees = await localDataSource.getActiveOtherFees();
      return Right(otherFees);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OtherFeeEntity>>> getOtherFeesByType(int toolType) async {
    try {
      final otherFees = await localDataSource.getOtherFeesByType(toolType);
      return Right(otherFees);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createOtherFee(OtherFeeEntity otherFee) async {
    try {
      final model = otherFee is OtherFeeModel ? otherFee : OtherFeeModel.fromEntity(otherFee);
      final id = await localDataSource.insertOtherFee(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateOtherFee(OtherFeeEntity otherFee) async {
    try {
      final model = otherFee is OtherFeeModel ? otherFee : OtherFeeModel.fromEntity(otherFee);
      await localDataSource.updateOtherFee(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOtherFee(int id) async {
    try {
      await localDataSource.deleteOtherFee(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OtherFeeEntity>>> searchOtherFees(String query) async {
    try {
      final otherFees = await localDataSource.searchOtherFees(query);
      return Right(otherFees);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

