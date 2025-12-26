import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../entities/voucher_entity.dart';
import '../repositories/voucher_repository.dart';

class VoucherFilterParams {
  final VoucherType? type;

  const VoucherFilterParams({this.type});
}

class GetVouchersUseCase
    implements Usecase<Either<Failure, List<VoucherEntity>>, VoucherFilterParams> {
  final VoucherRepository repository;

  GetVouchersUseCase(this.repository);

  @override
  Future<Either<Failure, List<VoucherEntity>>> call({
    required VoucherFilterParams params,
  }) {
    return repository.getVouchers(type: params.type);
  }
}

