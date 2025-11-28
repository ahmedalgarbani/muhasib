import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/data/datasources/region_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/region_model.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/region_repository.dart';

class RegionRepositoryImpl implements RegionRepository {
  final RegionLocalDataSource localDataSource;

  RegionRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<RegionEntity>>> getRegions() async {
    try {
      final regions = await localDataSource.getRegions();
      return Right(regions);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RegionEntity>> getRegionById(int id) async {
    try {
      final region = await localDataSource.getRegionById(id);
      return Right(region);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RegionEntity>>> getActiveRegions() async {
    try {
      final regions = await localDataSource.getActiveRegions();
      return Right(regions);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createRegion(RegionEntity region) async {
    try {
      final model = region is RegionModel ? region : RegionModel.fromEntity(region);
      final id = await localDataSource.insertRegion(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateRegion(RegionEntity region) async {
    try {
      final model = region is RegionModel ? region : RegionModel.fromEntity(region);
      await localDataSource.updateRegion(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRegion(int id) async {
    try {
      await localDataSource.deleteRegion(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RegionEntity>>> searchRegions(String query) async {
    try {
      final regions = await localDataSource.searchRegions(query);
      return Right(regions);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

