import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Get all return invoices (invoice_type = 4)
class GetReturnInvoices extends Usecase<Either<Failure, List<InvoiceEntity>>, NoParams> {
  final InvoiceRepository repository;

  GetReturnInvoices(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({
    required NoParams params,
  }) async {
    return await repository.getReturnInvoices();
  }
}
