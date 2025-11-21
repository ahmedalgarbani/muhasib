import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';

abstract class PurchaseRepository {
  // Purchase Invoices (invoice_type = 1 or 2, invoice_trans_type = 1)
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseInvoices();
  Future<Either<Failure, InvoiceEntity>> getPurchaseInvoice(int id);
  Future<Either<Failure, int>> createPurchaseInvoice(InvoiceEntity invoice);
  Future<Either<Failure, void>> updatePurchaseInvoice(InvoiceEntity invoice);
  Future<Either<Failure, void>> deletePurchaseInvoice(int id);
  
  // Purchase Orders (invoice_type = 3, invoice_trans_type = 1)
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseOrders();
  Future<Either<Failure, int>> createPurchaseOrder(InvoiceEntity order);
  Future<Either<Failure, int>> convertOrderToInvoice(int orderId, InvoiceEntity invoice);
  
  // Purchase Returns (invoice_type = 5, invoice_trans_type = 1)
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseReturns();
  Future<Either<Failure, int>> createPurchaseReturn(InvoiceEntity returnInvoice, int parentInvoiceId);
  Future<Either<Failure, List<InvoiceEntity>>> getReturnsByParentPurchase(int parentInvoiceId);
  
  // Search
  Future<Either<Failure, List<InvoiceEntity>>> searchPurchases(String query);
}
