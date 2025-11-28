import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/purchases/data/models/purchase_invoice_model.dart';
import 'package:muhasib/features/purchases/data/models/purchase_invoice_item_model.dart';
import 'package:muhasib/features/purchases/data/models/purchase_payment_model.dart';
import 'package:muhasib/features/purchases/data/models/supplier_model.dart';
import 'package:muhasib/features/purchases/domain/entities/purchase_invoice_item_entity.dart';
import 'package:sqflite/sqflite.dart';

abstract class PurchaseLocalDataSource {
  // Purchase Invoices
  Future<List<PurchaseInvoiceModel>> getAllPurchaseInvoices();
  Future<PurchaseInvoiceModel> getPurchaseInvoiceById(int id);
  Future<int> createPurchaseInvoice(PurchaseInvoiceModel invoice);
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice);
  Future<void> deletePurchaseInvoice(int id);
  Future<List<PurchaseInvoiceModel>> searchPurchaseInvoices(String query);
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoicesBySupplier(int supplierId);
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  // Purchase Returns
  Future<List<PurchaseInvoiceModel>> getPurchaseReturns();
  Future<int> createPurchaseReturn(PurchaseInvoiceModel returnInvoice);
  
  // Suppliers
  Future<List<SupplierModel>> getAllSuppliers();
  Future<SupplierModel> getSupplierById(int id);
  Future<int> createSupplier(SupplierModel supplier);
  Future<void> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(int id);
  Future<List<SupplierModel>> searchSuppliers(String query);
}

class PurchaseLocalDataSourceImpl implements PurchaseLocalDataSource {
  final Database database;
  
  static const String _invoicesTable = 'purchase_invoices';
  static const String _itemsTable = 'purchase_invoice_items';
  static const String _paymentsTable = 'purchase_payments';
  static const String _suppliersTable = 'suppliers';

  PurchaseLocalDataSourceImpl(this.database);

  @override
  Future<List<PurchaseInvoiceModel>> getAllPurchaseInvoices() async {
    try {
      final invoices = await database.query(
        _invoicesTable,
        where: 'invoice_type != ?',
        whereArgs: [2], // Exclude returns
        orderBy: 'invoice_date DESC, id DESC',
      );
      
      final List<PurchaseInvoiceModel> result = [];
      for (final invoice in invoices) {
        final items = await _getInvoiceItems(invoice['id'] as int);
        final payments = await _getInvoicePayments(invoice['id'] as int);
        final supplier = await _getSupplier(invoice['supplier_id'] as int);
        
        final invoiceData = Map<String, dynamic>.from(invoice);
        invoiceData['items'] = items;
        invoiceData['payments'] = payments;
        if (supplier != null) {
          invoiceData['supplier_name'] = supplier['name'];
          invoiceData['supplier_phone'] = supplier['contact'];
          invoiceData['supplier_address'] = supplier['address'];
        }
        
        result.add(PurchaseInvoiceModel.fromJson(invoiceData));
      }
      
      return result;
    } catch (e) {
      throw LocalStorageException('Failed to get purchase invoices: $e');
    }
  }

  @override
  Future<PurchaseInvoiceModel> getPurchaseInvoiceById(int id) async {
    try {
      final invoices = await database.query(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (invoices.isEmpty) {
        throw LocalStorageException('Purchase invoice not found');
      }
      
      final invoice = invoices.first;
      final items = await _getInvoiceItems(id);
      final payments = await _getInvoicePayments(id);
      final supplier = await _getSupplier(invoice['supplier_id'] as int);
      
      final invoiceData = Map<String, dynamic>.from(invoice);
      invoiceData['items'] = items;
      invoiceData['payments'] = payments;
      if (supplier != null) {
        invoiceData['supplier_name'] = supplier['name'];
        invoiceData['supplier_phone'] = supplier['contact'];
        invoiceData['supplier_address'] = supplier['address'];
      }
      
      return PurchaseInvoiceModel.fromJson(invoiceData);
    } catch (e) {
      throw LocalStorageException('Failed to get purchase invoice: $e');
    }
  }

  @override
  Future<int> createPurchaseInvoice(PurchaseInvoiceModel invoice) async {
    try {
      return await database.transaction((txn) async {
        // Ensure supplier exists
        await _ensureSupplier(txn, invoice.supplierId);
        
        // Insert invoice
        final invoiceData = invoice.toJson();
        invoiceData.remove('items');
        invoiceData.remove('payments');
        
        final invoiceId = await txn.insert(
          _invoicesTable,
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        
        // Insert items
        for (final item in invoice.items) {
          final itemModel = item is PurchaseInvoiceItemModel
              ? item
              : PurchaseInvoiceItemModel.fromEntity(item);
          await txn.insert(
            _itemsTable,
            itemModel.toJson(invoiceId: invoiceId),
          );
        }
        
        // Insert payments
        for (final payment in invoice.payments) {
          final paymentModel = payment is PurchasePaymentModel
              ? payment
              : PurchasePaymentModel.fromEntity(payment);
          await txn.insert(
            _paymentsTable,
            paymentModel.toJson(invoiceId: invoiceId),
          );
        }
        
        // Update inventory
        await _updateInventory(txn, invoice.items, true);
        
        // Update supplier balance
        if (invoice.remainingAmount > 0) {
          await _updateSupplierBalance(txn, invoice.supplierId, invoice.remainingAmount);
        }
        
        return invoiceId;
      });
    } catch (e) {
      throw LocalStorageException('Failed to create purchase invoice: $e');
    }
  }

  @override
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice) async {
    try {
      await database.transaction((txn) async {
        // Update invoice
        final invoiceData = invoice.toJson();
        invoiceData.remove('items');
        invoiceData.remove('payments');
        
        await txn.update(
          _invoicesTable,
          invoiceData,
          where: 'id = ?',
          whereArgs: [invoice.id],
        );
        
        // Delete old items and insert new ones
        await txn.delete(
          _itemsTable,
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        
        for (final item in invoice.items) {
          final itemModel = item is PurchaseInvoiceItemModel
              ? item
              : PurchaseInvoiceItemModel.fromEntity(item);
          await txn.insert(
            _itemsTable,
            itemModel.toJson(invoiceId: invoice.id),
          );
        }
        
        // Delete old payments and insert new ones
        await txn.delete(
          _paymentsTable,
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        
        for (final payment in invoice.payments) {
          final paymentModel = payment is PurchasePaymentModel
              ? payment
              : PurchasePaymentModel.fromEntity(payment);
          await txn.insert(
            _paymentsTable,
            paymentModel.toJson(invoiceId: invoice.id),
          );
        }
      });
    } catch (e) {
      throw LocalStorageException('Failed to update purchase invoice: $e');
    }
  }

  @override
  Future<void> deletePurchaseInvoice(int id) async {
    try {
      await database.transaction((txn) async {
        // Get invoice details first
        final invoices = await txn.query(
          _invoicesTable,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        
        if (invoices.isEmpty) return;
        
        // Delete invoice (items and payments will be cascade deleted)
        await txn.delete(
          _invoicesTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw LocalStorageException('Failed to delete purchase invoice: $e');
    }
  }

  @override
  Future<List<PurchaseInvoiceModel>> searchPurchaseInvoices(String query) async {
    try {
      final invoices = await database.query(
        _invoicesTable,
        where: 'invoice_number LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'invoice_date DESC, id DESC',
      );
      
      final List<PurchaseInvoiceModel> result = [];
      for (final invoice in invoices) {
        final items = await _getInvoiceItems(invoice['id'] as int);
        final payments = await _getInvoicePayments(invoice['id'] as int);
        final supplier = await _getSupplier(invoice['supplier_id'] as int);
        
        final invoiceData = Map<String, dynamic>.from(invoice);
        invoiceData['items'] = items;
        invoiceData['payments'] = payments;
        if (supplier != null) {
          invoiceData['supplier_name'] = supplier['name'];
          invoiceData['supplier_phone'] = supplier['contact'];
          invoiceData['supplier_address'] = supplier['address'];
        }
        
        result.add(PurchaseInvoiceModel.fromJson(invoiceData));
      }
      
      return result;
    } catch (e) {
      throw LocalStorageException('Failed to search purchase invoices: $e');
    }
  }

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoicesBySupplier(int supplierId) async {
    try {
      final invoices = await database.query(
        _invoicesTable,
        where: 'supplier_id = ?',
        whereArgs: [supplierId],
        orderBy: 'invoice_date DESC, id DESC',
      );
      
      final List<PurchaseInvoiceModel> result = [];
      for (final invoice in invoices) {
        final items = await _getInvoiceItems(invoice['id'] as int);
        final payments = await _getInvoicePayments(invoice['id'] as int);
        
        final invoiceData = Map<String, dynamic>.from(invoice);
        invoiceData['items'] = items;
        invoiceData['payments'] = payments;
        
        result.add(PurchaseInvoiceModel.fromJson(invoiceData));
      }
      
      return result;
    } catch (e) {
      throw LocalStorageException('Failed to get supplier invoices: $e');
    }
  }

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
      final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;
      
      final invoices = await database.query(
        _invoicesTable,
        where: 'invoice_date >= ? AND invoice_date <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: 'invoice_date DESC, id DESC',
      );
      
      final List<PurchaseInvoiceModel> result = [];
      for (final invoice in invoices) {
        final items = await _getInvoiceItems(invoice['id'] as int);
        final payments = await _getInvoicePayments(invoice['id'] as int);
        final supplier = await _getSupplier(invoice['supplier_id'] as int);
        
        final invoiceData = Map<String, dynamic>.from(invoice);
        invoiceData['items'] = items;
        invoiceData['payments'] = payments;
        if (supplier != null) {
          invoiceData['supplier_name'] = supplier['name'];
          invoiceData['supplier_phone'] = supplier['contact'];
          invoiceData['supplier_address'] = supplier['address'];
        }
        
        result.add(PurchaseInvoiceModel.fromJson(invoiceData));
      }
      
      return result;
    } catch (e) {
      throw LocalStorageException('Failed to get invoices by date range: $e');
    }
  }

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseReturns() async {
    try {
      final invoices = await database.query(
        _invoicesTable,
        where: 'invoice_type = ?',
        whereArgs: [2], // Returns only
        orderBy: 'invoice_date DESC, id DESC',
      );
      
      final List<PurchaseInvoiceModel> result = [];
      for (final invoice in invoices) {
        final items = await _getInvoiceItems(invoice['id'] as int);
        final payments = await _getInvoicePayments(invoice['id'] as int);
        final supplier = await _getSupplier(invoice['supplier_id'] as int);
        
        final invoiceData = Map<String, dynamic>.from(invoice);
        invoiceData['items'] = items;
        invoiceData['payments'] = payments;
        if (supplier != null) {
          invoiceData['supplier_name'] = supplier['name'];
          invoiceData['supplier_phone'] = supplier['contact'];
          invoiceData['supplier_address'] = supplier['address'];
        }
        
        result.add(PurchaseInvoiceModel.fromJson(invoiceData));
      }
      
      return result;
    } catch (e) {
      throw LocalStorageException('Failed to get purchase returns: $e');
    }
  }

  @override
  Future<int> createPurchaseReturn(PurchaseInvoiceModel returnInvoice) async {
    try {
      final invoiceWithReturn = returnInvoice.copyWith(invoiceType: 2);
      return await createPurchaseInvoice(invoiceWithReturn as PurchaseInvoiceModel);
    } catch (e) {
      throw LocalStorageException('Failed to create purchase return: $e');
    }
  }

  // Suppliers
  @override
  Future<List<SupplierModel>> getAllSuppliers() async {
    try {
      final suppliers = await database.query(
        _suppliersTable,
        where: 'type = ?',
        whereArgs: [1], // Supplier type
        orderBy: 'name ASC',
      );
      
      return suppliers.map((s) => SupplierModel.fromJson(s)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get suppliers: $e');
    }
  }

  @override
  Future<SupplierModel> getSupplierById(int id) async {
    try {
      final suppliers = await database.query(
        _suppliersTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (suppliers.isEmpty) {
        throw LocalStorageException('Supplier not found');
      }
      
      return SupplierModel.fromJson(suppliers.first);
    } catch (e) {
      throw LocalStorageException('Failed to get supplier: $e');
    }
  }

  @override
  Future<int> createSupplier(SupplierModel supplier) async {
    try {
      return await database.insert(
        _suppliersTable,
        supplier.toJson(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to create supplier: $e');
    }
  }

  @override
  Future<void> updateSupplier(SupplierModel supplier) async {
    try {
      await database.update(
        _suppliersTable,
        supplier.toJson(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
    } catch (e) {
      throw LocalStorageException('Failed to update supplier: $e');
    }
  }

  @override
  Future<void> deleteSupplier(int id) async {
    try {
      // Check if supplier has invoices
      final invoices = await database.query(
        _invoicesTable,
        where: 'supplier_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (invoices.isNotEmpty) {
        throw LocalStorageException('Cannot delete supplier with invoices');
      }
      
      await database.delete(
        _suppliersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalStorageException('Failed to delete supplier: $e');
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    try {
      final suppliers = await database.query(
        _suppliersTable,
        where: 'type = ? AND (name LIKE ? OR contact LIKE ?)',
        whereArgs: [1, '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      
      return suppliers.map((s) => SupplierModel.fromJson(s)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search suppliers: $e');
    }
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getInvoiceItems(int invoiceId) async {
    return await database.query(
      _itemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> _getInvoicePayments(int invoiceId) async {
    return await database.query(
      _paymentsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'payment_date ASC',
    );
  }

  Future<Map<String, dynamic>?> _getSupplier(int supplierId) async {
    final suppliers = await database.query(
      _suppliersTable,
      where: 'id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    
    return suppliers.isNotEmpty ? suppliers.first : null;
  }

  Future<void> _ensureSupplier(Transaction txn, int supplierId) async {
    final suppliers = await txn.query(
      _suppliersTable,
      where: 'id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    
    if (suppliers.isEmpty) {
      // Create default supplier if not exists
      await txn.insert(
        _suppliersTable,
        {
          'id': supplierId,
          'name': 'مورد افتراضي',
          'type': 1,
          'is_active': 1,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );
    }
  }

  Future<void> _updateInventory(
    Transaction txn,
    List<PurchaseInvoiceItemEntity> items,
    bool isAddition,
  ) async {
    for (final item in items) {
      // Get current stock
      final products = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [item.productId],
        limit: 1,
      );
      
      if (products.isNotEmpty) {
        final currentStock = (products.first['quantity'] as num?)?.toDouble() ?? 0.0;
        final newStock = isAddition
            ? currentStock + item.quantity
            : currentStock - item.quantity;
        
        // Update product quantity
        await txn.update(
          'products',
          {
            'quantity': newStock,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        
        // Create inventory transaction record
        await txn.insert('inventory_transactions', {
          'product_id': item.productId,
          'transaction_type': isAddition ? 'purchase' : 'purchase_return',
          'quantity': isAddition ? item.quantity : -item.quantity,
          'unit_price': item.unitPrice,
          'total_amount': item.totalPrice,
          'balance_after': newStock,
          'reference_type': 'purchase_invoice',
          'reference_id': item.id?.toString(),
          'transaction_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    }
  }

  Future<void> _updateSupplierBalance(
    Transaction txn,
    int supplierId,
    double amount,
  ) async {
    await txn.rawUpdate('''
      UPDATE suppliers 
      SET current_balance = current_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, supplierId]);
  }
}
