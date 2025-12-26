import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';

import '../entities/voucher_entity.dart';

abstract class VoucherRepository {
  Future<Either<Failure, List<VoucherEntity>>> getVouchers({VoucherType? type});
  Future<Either<Failure, VoucherEntity>> getVoucherById(int id);
  Future<Either<Failure, int>> addVoucher(VoucherEntity voucher);
  Future<Either<Failure, void>> updateVoucher(VoucherEntity voucher);
  Future<Either<Failure, void>> deleteVoucher(int id);
  Future<Either<Failure, int>> generateVoucherNumber(VoucherType type);
}

