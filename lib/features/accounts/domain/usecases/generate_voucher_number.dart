import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../entities/voucher_entity.dart';
import '../repositories/voucher_repository.dart';

class GenerateVoucherNumberUseCase
    implements Usecase<Either<Failure, int>, VoucherType> {
  final VoucherRepository repository;

  GenerateVoucherNumberUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call({required VoucherType params}) {
    return repository.generateVoucherNumber(params);
  }
}

