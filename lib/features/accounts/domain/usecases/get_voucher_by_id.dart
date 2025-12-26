import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../entities/voucher_entity.dart';
import '../repositories/voucher_repository.dart';

class GetVoucherByIdUseCase
    implements Usecase<Either<Failure, VoucherEntity>, int> {
  final VoucherRepository repository;

  GetVoucherByIdUseCase(this.repository);

  @override
  Future<Either<Failure, VoucherEntity>> call({required int params}) {
    return repository.getVoucherById(params);
  }
}

