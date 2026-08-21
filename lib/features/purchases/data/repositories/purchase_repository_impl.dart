import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
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
    dynamic journalRepository,
    dynamic accountConfigService,
  });

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseInvoices() async {
    try {
      final allInvoices = await localDataSource.getInvoices();
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
      if (invoice.invoiceType == InvoiceType.purchaseInvoice.value) {
        return Right(invoice);
      } else {
        return  Left(CacheFailure('Invoice is not a purchase invoice'));
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
      final purchaseInvoice = invoice.copyWith(
        invoiceType: InvoiceType.purchaseInvoice.value,
        invoiceTransType: invoice.invoiceTransType,
      );
      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseInvoice),
      );
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(CacheFailure(e.message));
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
      final purchaseInvoice = invoice.copyWith(
        invoiceType: InvoiceType.purchaseInvoice.value,
      );
      await localDataSource.updateInvoice(
        InvoiceModel.fromEntity(purchaseInvoice),
      );
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(CacheFailure(e.message));
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
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(CacheFailure(e.message));
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
      final purchaseOrders = allInvoices
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.quotation.value &&
                invoice.invoiceTransType == 1,
          )
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
      final purchaseOrder = order.copyWith(
        invoiceType: InvoiceType.quotation.value,
        invoiceTransType: 1,
      );
      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseOrder),
      );
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(CacheFailure(e.message));
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
      final order = await localDataSource.getInvoice(orderId);

      final purchaseInvoice = invoice.copyWith(
        invoiceType: InvoiceType.purchaseInvoice.value,
        parentInvoiceId: orderId,
        parentInvoiceNumber: order.number,
      );

      // استخدام التحويل الذري الجديد الذي يضمن الترحيل المحاسبي والمخزني والقفل
      try {
        final newId = await localDataSource.convertPurchaseOrderToInvoice(
          orderId,
          InvoiceModel.fromEntity(purchaseInvoice),
        );
        return Right(newId);
      } on NoSuchMethodError {
        // Fallback للتوافق الخلفي إذا لم يتوفر convertPurchaseOrderToInvoice بعد
        final newId = await localDataSource.insertInvoice(
          InvoiceModel.fromEntity(purchaseInvoice),
        );
        final updatedOrder = order.copyWith(
          nextInvoiceId: newId,
          nextInvoiceNumber: invoice.number,
        );
        await localDataSource.updateInvoice(
          InvoiceModel.fromEntity(updatedOrder),
        );
        return Right(newId);
      }
    } on LocalStorageException catch (e) {
      return Left(
        CacheFailure('Failed to convert order to invoice: ${e.message}'),
      );
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
      final parentInvoice = await localDataSource.getInvoice(parentInvoiceId);

      final purchaseReturn = returnInvoice.copyWith(
        invoiceType: InvoiceType.purchaseReturn.value,
        parentInvoiceId: parentInvoiceId,
        parentInvoiceNumber: parentInvoice.number,
      );

      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseReturn),
      );

      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(CacheFailure(e.message));
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
      final purchaseResults = searchResults
          .where(
            (invoice) =>
                invoice.invoiceType == InvoiceType.purchaseInvoice.value ||
                invoice.invoiceType == InvoiceType.purchaseReturn.value ||
                (invoice.invoiceType == InvoiceType.quotation.value &&
                    invoice.invoiceTransType == 1),
          )
          .toList();
      return Right(purchaseResults);
    } catch (e) {
      return Left(CacheFailure('Failed to search purchases: ${e.toString()}'));
    }
  }
}
