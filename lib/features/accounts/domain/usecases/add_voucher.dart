import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../entities/voucher_entity.dart';
import '../repositories/voucher_repository.dart';

class AddVoucherUseCase implements Usecase<Either<Failure, int>, VoucherEntity> {
  final VoucherRepository repository;

  AddVoucherUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call({required VoucherEntity params}) {
    return repository.addVoucher(params);
  }
}

