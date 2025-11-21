import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class UpdateInvoice implements Usecase<Either<Failure, void>, InvoiceEntity> {
  final InvoiceRepository repository;
  UpdateInvoice(this.repository);

  @override
  Future<Either<Failure, void>> call({required InvoiceEntity params}) async {
    return await repository.updateInvoice(params);
  }
}
