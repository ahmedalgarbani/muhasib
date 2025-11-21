import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Convert a quotation to a sales invoice
/// 
/// This use case:
/// 1. Creates a new sales invoice based on the quotation
/// 2. Updates the quotation status to "converted"
/// 3. Links the quotation to the new invoice
class ConvertQuotationToInvoice extends Usecase<Either<Failure, int>, ConvertQuotationParams> {
  final InvoiceRepository repository;

  ConvertQuotationToInvoice(this.repository);

  @override
  Future<Either<Failure, int>> call({
    required ConvertQuotationParams params,
  }) async {
    return await repository.convertQuotationToInvoice(
      params.quotationId,
      params.salesInvoice,
    );
  }
}

class ConvertQuotationParams extends Equatable {
  final int quotationId;
  final InvoiceEntity salesInvoice;

  const ConvertQuotationParams({
    required this.quotationId,
    required this.salesInvoice,
  });

  @override
  List<Object?> get props => [quotationId, salesInvoice];
}
