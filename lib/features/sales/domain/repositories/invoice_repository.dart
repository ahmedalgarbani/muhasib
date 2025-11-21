import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';

abstract class InvoiceRepository {
  // Basic CRUD operations
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices();
  Future<Either<Failure, InvoiceEntity>> getInvoice(int id);
  Future<Either<Failure, int>> createInvoice(InvoiceEntity invoice);
  Future<Either<Failure, void>> updateInvoice(InvoiceEntity invoice);
  Future<Either<Failure, void>> deleteInvoice(int id);
  Future<Either<Failure, List<InvoiceEntity>>> searchInvoices(String query);
  
  // Filter by invoice type
  Future<Either<Failure, List<InvoiceEntity>>> getInvoicesByType(int invoiceType);
  
  // Quotation-specific methods
  Future<Either<Failure, List<InvoiceEntity>>> getQuotations();
  Future<Either<Failure, List<InvoiceEntity>>> getOpenQuotations(); // Not converted
  Future<Either<Failure, int>> convertQuotationToInvoice(
    int quotationId,
    InvoiceEntity salesInvoice,
  );
  
  // Return invoice methods
  Future<Either<Failure, List<InvoiceEntity>>> getReturnInvoices();
  Future<Either<Failure, List<InvoiceEntity>>> getReturnsByParentInvoice(
    int parentInvoiceId,
  );
  Future<Either<Failure, int>> createReturnInvoice(
    InvoiceEntity returnInvoice,
    int parentInvoiceId,
  );
  
  // Get invoices by customer
  Future<Either<Failure, List<InvoiceEntity>>> getInvoicesByCustomer(
    int customerId,
  );
}
