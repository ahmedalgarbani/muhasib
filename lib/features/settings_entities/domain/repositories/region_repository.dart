import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';

abstract class RegionRepository {
  Future<Either<Failure, List<RegionEntity>>> getRegions();
  Future<Either<Failure, RegionEntity>> getRegionById(int id);
  Future<Either<Failure, List<RegionEntity>>> getActiveRegions();
  Future<Either<Failure, int>> createRegion(RegionEntity region);
  Future<Either<Failure, void>> updateRegion(RegionEntity region);
  Future<Either<Failure, void>> deleteRegion(int id);
  Future<Either<Failure, List<RegionEntity>>> searchRegions(String query);
}

