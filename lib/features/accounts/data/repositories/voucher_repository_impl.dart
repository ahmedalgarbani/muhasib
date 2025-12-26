import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';

import '../../domain/entities/voucher_entity.dart';
import '../../domain/repositories/voucher_repository.dart';
import '../datasources/voucher_local_datasource.dart';
import '../models/voucher_model.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final VoucherLocalDataSource localDataSource;

  VoucherRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, int>> addVoucher(VoucherEntity voucher) async {
    try {
      final id = await localDataSource.insertVoucher(
        VoucherModel.fromEntity(voucher),
      );
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVoucher(int id) async {
    try {
      await localDataSource.deleteVoucher(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> generateVoucherNumber(VoucherType type) async {
    try {
      final number = await localDataSource.generateVoucherNumber(type);
      return Right(number);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VoucherEntity>> getVoucherById(int id) async {
    try {
      final voucher = await localDataSource.getVoucher(id);
      return Right(voucher);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VoucherEntity>>> getVouchers({
    VoucherType? type,
  }) async {
    try {
      final vouchers = await localDataSource.getVouchers(type: type);
      return Right(vouchers);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVoucher(VoucherEntity voucher) async {
    try {
      await localDataSource.updateVoucher(
        VoucherModel.fromEntity(voucher),
      );
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

