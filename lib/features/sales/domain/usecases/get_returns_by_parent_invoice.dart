import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Get return invoices for a specific parent invoice
class GetReturnsByParentInvoice
    extends Usecase<Either<Failure, List<InvoiceEntity>>, int> {
  final InvoiceRepository repository;

  GetReturnsByParentInvoice(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({
    required int params,
  }) async {
    return await repository.getReturnsByParentInvoice(params);
  }
}
