import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:intl/intl.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final InvoiceLocalDataSource localDataSource;
  final JournalRepository? journalRepository;
  final AccountConfigService? accountConfigService;

  PurchaseRepositoryImpl({
    required this.localDataSource,
    this.journalRepository,
    this.accountConfigService,
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

      // ---------- Double‑Entry Accounting ----------
      // Build a balanced journal entry: Debit Inventory, Credit Supplier
      if (journalRepository != null && accountConfigService != null) {
        final purchaseConfig = await accountConfigService!.getPurchaseAccountConfig();
        final inventoryAcc = purchaseConfig.inventoryAccountId;
        final supplierAcc = purchaseConfig.suppliersAccountId;
        final total = purchaseInvoice.totalAmount ?? 0.0;

        final journalEntry = JournalEntryModel(
          number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
          entryDate: DateTime.now(),
          description: 'فاتورة شراء ${purchaseInvoice.number}',
          referenceNumber: purchaseInvoice.number,
          totalDebit: total,
          totalCredit: total,
          difference: 0.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: inventoryAcc,
              accountName: 'المخزون',
              currencyCode: 'SAR',
              debit: total,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: supplierAcc,
              accountName: 'الموردين',
              currencyCode: 'SAR',
              debit: 0.0,
              credit: total,
            ),
          ],
        );
        await journalRepository!.createJournalEntry(journalEntry);
      }
      // --------------------------------------------

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
      // Get old invoice for reversing entry
      InvoiceEntity? oldInvoice;
      if (invoice.id != null && journalRepository != null && accountConfigService != null) {
        try {
          oldInvoice = await localDataSource.getInvoice(invoice.id!);
        } catch (_) {}
      }
      
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
      
      // ---------- Double‑Entry Accounting (Update) ----------
      // Reverse old entry and create new entry
      if (journalRepository != null && accountConfigService != null) {
        final purchaseConfig = await accountConfigService!.getPurchaseAccountConfig();
        final inventoryAcc = purchaseConfig.inventoryAccountId;
        final supplierAcc = purchaseConfig.suppliersAccountId;
        
        // Reverse old entry if exists
        if (oldInvoice != null) {
          final oldTotal = oldInvoice.totalAmount ?? 0.0;
          if (oldTotal > 0) {
            final reversingEntry = JournalEntryModel(
              number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
              entryDate: DateTime.now(),
              description: 'قيد عكسي - تعديل فاتورة شراء ${oldInvoice.number}',
              referenceNumber: oldInvoice.number,
              totalDebit: oldTotal,
              totalCredit: oldTotal,
              difference: 0.0,
              lines: [
                JournalEntryLineModel(
                  lineNumber: 1,
                  accountId: inventoryAcc,
                  accountName: 'المخزون',
                  currencyCode: 'SAR',
                  debit: 0.0,
                  credit: oldTotal,
                ),
                JournalEntryLineModel(
                  lineNumber: 2,
                  accountId: supplierAcc,
                  accountName: 'الموردين',
                  currencyCode: 'SAR',
                  debit: oldTotal,
                  credit: 0.0,
                ),
              ],
            );
            await journalRepository!.createJournalEntry(reversingEntry);
          }
        }
        
        // Create new entry for updated invoice
        final newTotal = purchaseInvoice.totalAmount ?? 0.0;
        if (newTotal > 0) {
          final newEntry = JournalEntryModel(
            number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
            entryDate: DateTime.now(),
            description: 'فاتورة شراء (معدلة) ${purchaseInvoice.number}',
            referenceNumber: purchaseInvoice.number,
            totalDebit: newTotal,
            totalCredit: newTotal,
            difference: 0.0,
            lines: [
              JournalEntryLineModel(
                lineNumber: 1,
                accountId: inventoryAcc,
                accountName: 'المخزون',
                currencyCode: 'SAR',
                debit: newTotal,
                credit: 0.0,
              ),
              JournalEntryLineModel(
                lineNumber: 2,
                accountId: supplierAcc,
                accountName: 'الموردين',
                currencyCode: 'SAR',
                debit: 0.0,
                credit: newTotal,
              ),
            ],
          );
          await journalRepository!.createJournalEntry(newEntry);
        }
      }
      // ------------------------------------------------------

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
      // Fetch invoice before deletion to get the amount for reversing entry
      InvoiceEntity? invoiceToDelete;
      try {
        invoiceToDelete = await localDataSource.getInvoice(id);
      } catch (_) {
        // Invoice not found, proceed with deletion only
      }
      
      await localDataSource.deleteInvoice(id);
      
      // ---------- Double‑Entry Accounting (Delete) ----------
      // Create a reversing entry with opposite signs
      if (journalRepository != null && accountConfigService != null && invoiceToDelete != null) {
        final purchaseConfig = await accountConfigService!.getPurchaseAccountConfig();
        final inventoryAcc = purchaseConfig.inventoryAccountId;
        final supplierAcc = purchaseConfig.suppliersAccountId;
        final total = invoiceToDelete.totalAmount ?? 0.0;
        
        if (total > 0) {
          final reversingEntry = JournalEntryModel(
            number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
            entryDate: DateTime.now(),
            description: 'قيد عكسي - حذف فاتورة شراء ${invoiceToDelete.number}',
            referenceNumber: invoiceToDelete.number,
            totalDebit: total,
            totalCredit: total,
            difference: 0.0,
            lines: [
              JournalEntryLineModel(
                lineNumber: 1,
                accountId: inventoryAcc,
                accountName: 'المخزون',
                currencyCode: 'SAR',
                debit: 0.0,
                credit: total, // Reverse: was debit, now credit
              ),
              JournalEntryLineModel(
                lineNumber: 2,
                accountId: supplierAcc,
                accountName: 'الموردين',
                currencyCode: 'SAR',
                debit: total, // Reverse: was credit, now debit
                credit: 0.0,
              ),
            ],
          );
          await journalRepository!.createJournalEntry(reversingEntry);
        }
      }
      // ------------------------------------------------------
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

      // insertInvoice now handles ID removal automatically
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

      // ---------- Double‑Entry Accounting (Order to Invoice) ----------
      // Create journal entry for the new purchase invoice
      if (journalRepository != null && accountConfigService != null) {
        final purchaseConfig = await accountConfigService!.getPurchaseAccountConfig();
        final inventoryAcc = purchaseConfig.inventoryAccountId;
        final supplierAcc = purchaseConfig.suppliersAccountId;
        final total = purchaseInvoice.totalAmount ?? 0.0;

        if (total > 0) {
          final journalEntry = JournalEntryModel(
            number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
            entryDate: DateTime.now(),
            description: 'فاتورة شراء (محولة من أمر) ${purchaseInvoice.number}',
            referenceNumber: purchaseInvoice.number,
            totalDebit: total,
            totalCredit: total,
            difference: 0.0,
            lines: [
              JournalEntryLineModel(
                lineNumber: 1,
                accountId: inventoryAcc,
                accountName: 'المخزون',
                currencyCode: 'SAR',
                debit: total,
                credit: 0.0,
              ),
              JournalEntryLineModel(
                lineNumber: 2,
                accountId: supplierAcc,
                accountName: 'الموردين',
                currencyCode: 'SAR',
                debit: 0.0,
                credit: total,
              ),
            ],
          );
          await journalRepository!.createJournalEntry(journalEntry);
        }
      }
      // ------------------------------------------------------

      return Right(newId);
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

      // Create return with reference to parent - include ALL accounting fields
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
        taxAmt: returnInvoice.taxAmt,
        taxRatio: returnInvoice.taxRatio,
        discountAmt: returnInvoice.discountAmt,
        discountRatio: returnInvoice.discountRatio,
        otherFeeAmt: returnInvoice.otherFeeAmt,
        otherFeeNetRatio: returnInvoice.otherFeeNetRatio,
        otherFeeAccountId: returnInvoice.otherFeeAccountId,
        totalAmountAfterDiscount: returnInvoice.totalAmountAfterDiscount,
        netRevenueAmt: returnInvoice.netRevenueAmt,
        finalAmt: returnInvoice.finalAmt,
        currencyId: returnInvoice.currencyId,
        taxId: returnInvoice.taxId,
        statement: returnInvoice.statement,
        lines: returnInvoice.lines,
        paymentStatus: returnInvoice.paymentStatus,
        dueDate: returnInvoice.dueDate,
        shippingAddress: returnInvoice.shippingAddress,
      );

      final id = await localDataSource.insertInvoice(
        InvoiceModel.fromEntity(purchaseReturn),
      );

      // ========== UPDATE INVENTORY - Reduce stock for returned items ==========
      final db = await databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      for (final line in returnInvoice.lines) {
        final productId = line.categoryId;
        final warehouseId = line.stockId ?? returnInvoice.stockId ?? 1;
        final returnQty = line.quantity;
        
        if (productId != null && returnQty > 0) {
          // Get current stock
          final stockResult = await db.query(
            'warehouse_stocks',
            where: 'product_id = ? AND warehouse_id = ?',
            whereArgs: [productId, warehouseId],
            limit: 1,
          );
          
          if (stockResult.isNotEmpty) {
            final currentQty = (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;
            final avgCost = (stockResult.first['avg_cost'] as num?)?.toDouble() ?? 
                           (line.costPrice ?? line.price);
            final newQty = currentQty - returnQty;
            
            // Update stock - reduce quantity
            await db.update(
              'warehouse_stocks',
              {
                'quantity': newQty,
                'last_modification_time': now,
              },
              where: 'product_id = ? AND warehouse_id = ?',
              whereArgs: [productId, warehouseId],
            );
            
            // Record stock movement
            try {
              await db.insert('stock_movements', {
                'product_id': productId,
                'warehouse_id': warehouseId,
                'movement_type': 'return_purchase',
                'quantity': -returnQty, // Negative = outgoing
                'unit_cost': avgCost,
                'total_cost': returnQty * avgCost,
                'balance_after': newQty,
                'reference_type': 'purchase_return',
                'reference_id': id,
                'reference_number': returnInvoice.number,
                'creation_time': now,
              });
            } catch (_) {
              // Ignore if stock_movements table doesn't exist
            }
          }
        }
      }
      // ========== END INVENTORY UPDATE ==========

      // ---------- Double‑Entry Accounting (Purchase Return) ----------
      // Debit: Supplier/Cash | Credit: Inventory + Tax
      if (journalRepository != null && accountConfigService != null) {
        final purchaseConfig = await accountConfigService!.getPurchaseAccountConfig();
        final inventoryAcc = purchaseConfig.inventoryAccountId;
        final supplierAcc = purchaseConfig.suppliersAccountId;
        final taxAcc = purchaseConfig.taxAccountId;
        
        final amount = purchaseReturn.totalAmount ?? 0.0;
        final taxAmount = purchaseReturn.taxAmt ?? 0.0;
        final netAmount = amount + taxAmount;
        
        if (netAmount > 0) {
          final lines = <JournalEntryLineModel>[];
          int lineNumber = 1;
          
          // Debit: Supplier (we get money back or reduce payable)
          lines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: supplierAcc,
            accountName: 'الموردين',
            currencyCode: 'SAR',
            debit: netAmount,
            credit: 0.0,
          ));
          
          // Credit: Inventory (we return goods)
          if (amount > 0) {
            lines.add(JournalEntryLineModel(
              lineNumber: lineNumber++,
              accountId: inventoryAcc,
              accountName: 'المخزون',
              currencyCode: 'SAR',
              debit: 0.0,
              credit: amount,
            ));
          }
          
          // Credit: Tax (if applicable)
          if (taxAmount > 0) {
            lines.add(JournalEntryLineModel(
              lineNumber: lineNumber++,
              accountId: taxAcc,
              accountName: 'ضريبة القيمة المضافة',
              currencyCode: 'SAR',
              debit: 0.0,
              credit: taxAmount,
            ));
          }
          
          final returnEntry = JournalEntryModel(
            number: 'JE-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
            entryDate: DateTime.now(),
            description: 'مرتجع مشتريات رقم ${purchaseReturn.number}',
            referenceNumber: purchaseReturn.number,
            totalDebit: netAmount,
            totalCredit: netAmount,
            difference: 0.0,
            lines: lines,
          );
          await journalRepository!.createJournalEntry(returnEntry);
        }
      }
      // ------------------------------------------------------

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
