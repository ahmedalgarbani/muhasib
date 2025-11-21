import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class CreateInvoice implements Usecase<Either<Failure, int>, InvoiceEntity> {
  final InvoiceRepository repository;
  CreateInvoice(this.repository);

  @override
  Future<Either<Failure, int>> call({required InvoiceEntity params}) async {
    return await repository.createInvoice(params);
  }
}
