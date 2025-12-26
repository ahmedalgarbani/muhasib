import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final InvoiceLocalDataSource localDataSource;

  PurchaseRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseInvoices() async {
    try {
      final allInvoices = await localDataSource.getInvoices();
      // Purchase invoices (invoice_type = 2)
      final purchaseInvoices = allInvoices
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.purchaseInvoice.value,
          )
          .toList();
      return Right(purchaseInvoices);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load purchase invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getPurchaseInvoice(int id) async {
    try {
      final invoice = await localDataSource.getInvoice(id);
      // Verify it's a purchase invoice
      if (invoice.invoiceType == InvoiceType.purchaseInvoice.value) {
        return Right(invoice);
      } else {
        return Left(CacheFailure('Invoice is not a purchase invoice'));
      }
    } catch (e) {
      return Left(
        CacheFailure('Failed to load purchase invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> createPurchaseInvoice(
    InvoiceEntity invoice,
  ) async {
    try {
      // Create a purchase invoice entity with correct type
      final purchaseInvoice = InvoiceEntity(
        invoiceType: InvoiceType.purchaseInvoice.value,
        invoiceTransType: invoice.invoiceTransType,
        number: invoice.number,
        date: invoice.date,
        customerId: invoice.customerId,
        stockId: invoice.stockId,
        amount: invoice.amount,
        totalAmount: invoice.totalAmount,
        finalAmt: invoice.finalAmt,
        taxAmt: invoice.taxAmt,
        discountAmt: invoice.discountAmt,
        statement: invoice.statement,
        lines: invoice.lines,
        paymentStatus: invoice.paymentStatus,
        dueDate: invoice.dueDate,
        shippingAddress: invoice.shippingAddress,
      );
      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseInvoice),
      );

      return Right(id);
    } catch (e) {
      return Left(
        CacheFailure('Failed to create purchase invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updatePurchaseInvoice(
    InvoiceEntity invoice,
  ) async {
    try {
      // Ensure it remains a purchase invoice
      final purchaseInvoice = InvoiceEntity(
        id: invoice.id,
        invoiceType: InvoiceType.purchaseInvoice.value,
        invoiceTransType: 1,
        number: invoice.number,
        date: invoice.date,
        customerId: invoice.customerId,
        stockId: invoice.stockId,
        amount: invoice.amount,
        totalAmount: invoice.totalAmount,
        finalAmt: invoice.finalAmt,
        taxAmt: invoice.taxAmt,
        discountAmt: invoice.discountAmt,
        statement: invoice.statement,
        lines: invoice.lines,
        paymentStatus: invoice.paymentStatus,
        dueDate: invoice.dueDate,
        shippingAddress: invoice.shippingAddress,
      );
      await localDataSource.updateInvoice(
        InvoiceModel.fromEntity(purchaseInvoice),
      );
      
      // TODO: Update accounting entries (reverse old, create new, or update)
      // For now, we are not handling updates to accounting entries automatically
      // This requires finding the old entry by reference and updating it.

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to update purchase invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseInvoice(int id) async {
    try {
      await localDataSource.deleteInvoice(id);
      // TODO: Delete or reverse accounting entries
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to delete purchase invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseOrders() async {
    try {
      final allInvoices = await localDataSource.getInvoices();
      // Filter for purchase orders (using quotation type for orders)
      final purchaseOrders = allInvoices
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.quotation.value &&
                invoice.invoiceTransType == 1,
          ) // Purchase transaction
          .toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load purchase orders: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> createPurchaseOrder(InvoiceEntity order) async {
    try {
      // Use quotation type for purchase orders
      final purchaseOrder = InvoiceEntity(
        invoiceType: InvoiceType.quotation.value,
        invoiceTransType: 1, // Purchase transaction
        number: order.number,
        date: order.date,
        customerId: order.customerId,
        stockId: order.stockId,
        amount: order.amount,
        totalAmount: order.totalAmount,
        finalAmt: order.finalAmt,
        statement: order.statement,
        lines: order.lines,
        paymentStatus: order.paymentStatus,
        dueDate: order.dueDate,
        shippingAddress: order.shippingAddress,
      );
      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseOrder),
      );
      return Right(id);
    } catch (e) {
      return Left(
        CacheFailure('Failed to create purchase order: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> convertOrderToInvoice(
    int orderId,
    InvoiceEntity invoice,
  ) async {
    try {
      // Get the original order
      final order = await localDataSource.getInvoice(orderId);

      // Create new purchase invoice from order
      final purchaseInvoice = InvoiceEntity(
        invoiceType: InvoiceType.purchaseInvoice.value,
        invoiceTransType: invoice.invoiceTransType,
        parentInvoiceId: orderId,
        parentInvoiceNumber: order.number,
        number: invoice.number,
        date: invoice.date,
        customerId: invoice.customerId,
        stockId: invoice.stockId,
        amount: invoice.amount,
        totalAmount: invoice.totalAmount,
        finalAmt: invoice.finalAmt,
        statement: invoice.statement,
        lines: invoice.lines,
        paymentStatus: invoice.paymentStatus,
        dueDate: invoice.dueDate,
        shippingAddress: invoice.shippingAddress,
      );

      final newId = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseInvoice),
      );

      // Update original order to mark as converted
      final updatedOrder = InvoiceEntity(
        id: order.id,
        invoiceType: order.invoiceType,
        invoiceTransType: order.invoiceTransType,
        nextInvoiceId: newId,
        nextInvoiceNumber: invoice.number,
        number: order.number,
        date: order.date,
        customerId: order.customerId,
        stockId: order.stockId,
        amount: order.amount,
        totalAmount: order.totalAmount,
        finalAmt: order.finalAmt,
        statement: order.statement,
        lines: order.lines,
        paymentStatus: order.paymentStatus,
        dueDate: order.dueDate,
        shippingAddress: order.shippingAddress,
      );
      await localDataSource.updateInvoice(
        InvoiceModel.fromEntity(updatedOrder),
      );

      return Right(newId);
    } catch (e) {
      return Left(
        CacheFailure('Failed to convert order to invoice: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseReturns() async {
    try {
      final allInvoices = await localDataSource.getInvoices();
      // Filter for purchase returns
      final purchaseReturns = allInvoices
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.purchaseReturn.value,
          )
          .toList();
      return Right(purchaseReturns);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load purchase returns: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> createPurchaseReturn(
    InvoiceEntity returnInvoice,
    int parentInvoiceId,
  ) async {
    try {
      // Get parent purchase invoice
      final parentInvoice = await localDataSource.getInvoice(parentInvoiceId);

      // Create return with reference to parent
      final purchaseReturn = InvoiceEntity(
        invoiceType: InvoiceType.purchaseReturn.value,
        invoiceTransType: returnInvoice.invoiceTransType,
        parentInvoiceId: parentInvoiceId,
        parentInvoiceNumber: parentInvoice.number,
        number: returnInvoice.number,
        date: returnInvoice.date,
        customerId: returnInvoice.customerId,
        stockId: returnInvoice.stockId,
        amount: returnInvoice.amount,
        totalAmount: returnInvoice.totalAmount,
        finalAmt: returnInvoice.finalAmt,
        statement: returnInvoice.statement,
        lines: returnInvoice.lines,
        paymentStatus: returnInvoice.paymentStatus,
        dueDate: returnInvoice.dueDate,
        shippingAddress: returnInvoice.shippingAddress,
      );

      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseReturn),
      );

      return Right(id);
    } catch (e) {
      return Left(
        CacheFailure('Failed to create purchase return: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getReturnsByParentPurchase(
    int parentInvoiceId,
  ) async {
    try {
      final allInvoices = await localDataSource.getInvoices();
      // Filter for returns of specific purchase
      final returns = allInvoices
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.purchaseReturn.value &&
                invoice.parentInvoiceId == parentInvoiceId,
          )
          .toList();
      return Right(returns);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load purchase returns: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> searchPurchases(
    String query,
  ) async {
    try {
      final searchResults = await localDataSource.searchInvoices(query);
      // Filter for purchase-related invoices only
      final purchaseResults = searchResults
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.purchaseInvoice.value ||
                invoice.invoiceType == InvoiceType.purchaseReturn.value ||
                (invoice.invoiceType == InvoiceType.quotation.value &&
                    invoice.invoiceTransType == 1), // purchase orders
          )
          .toList();
      return Right(purchaseResults);
    } catch (e) {
      return Left(CacheFailure('Failed to search purchases: ${e.toString()}'));
    }
  }
}
