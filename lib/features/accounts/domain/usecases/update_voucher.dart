import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../entities/voucher_entity.dart';
import '../repositories/voucher_repository.dart';

class UpdateVoucherUseCase
    implements Usecase<Either<Failure, void>, VoucherEntity> {
  final VoucherRepository repository;

  UpdateVoucherUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call({required VoucherEntity params}) {
    return repository.updateVoucher(params);
  }
}

