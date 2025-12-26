import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../repositories/voucher_repository.dart';

class DeleteVoucherUseCase implements Usecase<Either<Failure, void>, int> {
  final VoucherRepository repository;

  DeleteVoucherUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call({required int params}) {
    return repository.deleteVoucher(params);
  }
}

