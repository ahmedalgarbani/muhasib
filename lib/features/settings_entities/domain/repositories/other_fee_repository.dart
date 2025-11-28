import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';

abstract class OtherFeeRepository {
  Future<Either<Failure, List<OtherFeeEntity>>> getOtherFees();
  Future<Either<Failure, OtherFeeEntity>> getOtherFeeById(int id);
  Future<Either<Failure, List<OtherFeeEntity>>> getActiveOtherFees();
  Future<Either<Failure, List<OtherFeeEntity>>> getOtherFeesByType(int toolType);
  Future<Either<Failure, int>> createOtherFee(OtherFeeEntity otherFee);
  Future<Either<Failure, void>> updateOtherFee(OtherFeeEntity otherFee);
  Future<Either<Failure, void>> deleteOtherFee(int id);
  Future<Either<Failure, List<OtherFeeEntity>>> searchOtherFees(String query);
}

