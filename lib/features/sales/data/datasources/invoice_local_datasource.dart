import 'package:muhasib/core/errors/exceptions.dart';
import 'package:sqflite/sqflite.dart';

import '../models/invoice_line_model.dart';
import '../models/invoice_model.dart';

abstract class InvoiceLocalDataSource {
  Future<List<InvoiceModel>> getInvoices();
  Future<InvoiceModel> getInvoice(int id);
  Future<int> insertInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(int id);
  Future<List<InvoiceModel>> searchInvoices(String query);
  
  // Filter operations
  Future<List<InvoiceModel>> getInvoicesByType(int invoiceType);
  Future<List<InvoiceModel>> getInvoicesByCustomer(int customerId);
  
  // Quotations
  Future<List<InvoiceModel>> getQuotations();
  Future<List<InvoiceModel>> getOpenQuotations();
  Future<int> convertQuotationToInvoice(
    int quotationId,
    InvoiceModel salesInvoice,
  );
  
  // Returns
  Future<List<InvoiceModel>> getReturnInvoices();
  Future<List<InvoiceModel>> getReturnsByParentInvoice(int parentInvoiceId);
  Future<int> createReturnInvoice(
    InvoiceModel returnInvoice,
    int parentInvoiceId,
  );
}

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  static const String _invoicesTable = 'invoices';
  static const String _linesTable = 'invoice_lines';

  final Database database;

  InvoiceLocalDataSourceImpl({required this.database});

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final heads = await database.query(
        _invoicesTable,
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];

      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }

      return results;
    } catch (e) {
      throw LocalStorageException('Failed to load invoices: ${e.toString()}');
    }
  }

  @override
  Future<InvoiceModel> getInvoice(int id) async {
    try {
      final rows = await database.query(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw LocalStorageException('Invoice with id $id not found');
      }
      final lines = await database.query(
        _linesTable,
        where: 'invoice_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
      final lineModels = lines
          .map((e) => InvoiceLineModel.fromJson(e))
          .toList();
      return InvoiceModel.fromJson(rows.first, lines: lineModels);
    } catch (e) {
      throw LocalStorageException('Failed to get invoice: ${e.toString()}');
    }
  }

  @override
  Future<int> insertInvoice(InvoiceModel invoice) async {
    try {
      return await database.transaction((txn) async {
        // Prepare invoice data with creation_time if not set
        final invoiceData = invoice.toJson();
        invoiceData['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
        invoiceData['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
        
        // ========== Ensure FK targets exist (defensive seeding) ==========
        // 1) Classifications (needed for customers)
        final classificationsCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(1) FROM classifications'),
        ) ?? 0;
        if (classificationsCount == 0) {
          final now = DateTime.now().millisecondsSinceEpoch;
          await txn.insert('classifications', {
            'id': 1,
            'name': 'عملاء عاديين',
            'singler_name': 'عميل',
            'order': 1,
            'type': 1,
            'creation_time': now,
            'last_modification_time': now,
          });
        }

        // 2) Customers (seed id 1 cash, id 2 credit if missing)
        Future<void> _ensureCustomer(int id, String name, int type) async {
          final rows = await txn.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
          if (rows.isEmpty) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // seconds to match CHECK
            await txn.insert('customers', {
              'id': id,
              'name': name,
              'type': type,
              'classification': 1,
              'classification_id': 1,
              'is_active': 1,
              'credit_limit': 0.0,
              'current_balance': 0.0,
              'creation_time': now,
              'last_modification_time': now,
            });
          }
        }
        await _ensureCustomer(1, 'عميل نقدي', 1);
        await _ensureCustomer(2, 'عميل آجل', 2);

        // 3) Stocks (seed main stock id 1 if missing)
        final stockId = invoiceData['stock_id'] as int?;
        Future<int> _ensureStock(int? desiredId) async {
          if (desiredId != null) {
            final rows = await txn.query('stocks', where: 'id = ?', whereArgs: [desiredId], limit: 1);
            if (rows.isNotEmpty) return desiredId;
          }
          // Try any existing stock
          final anyStock = await txn.query('stocks', limit: 1);
          if (anyStock.isNotEmpty) return anyStock.first['id'] as int;
          // Seed default main stock
          final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await txn.insert('stocks', {
            'id': 1,
            'name': 'المخزن الرئيسي',
            'address': 'المقر الرئيسي',
            'is_main_stock': 1,
            'is_active': 1,
            'creation_time': nowSec,
            'last_modification_time': nowSec,
          });
          return 1;
        }
        invoiceData['stock_id'] = await _ensureStock(stockId);

        // Ensure customer id points to an existing row (fallback to 1)
        int desiredCustomerId = (invoiceData['customer_id'] as int?) ?? 1;
        final cust = await txn.query('customers', where: 'id = ?', whereArgs: [desiredCustomerId], limit: 1);
        if (cust.isEmpty) {
          desiredCustomerId = 1;
        }
        invoiceData['customer_id'] = desiredCustomerId;
        
        final invoiceId = await txn.insert(
          _invoicesTable,
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        for (final line in invoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          
          // Prepare line data with creation_time if not set  
          final lineData = lineModel.toJson(invoiceId: invoiceId);
          lineData['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
          lineData['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;

          // ========= Enforce/derive valid foreign keys for invoice_lines =========
          // currency_id -> nullable: if provided but not found, set to null
          final int? _currencyId = lineData['currency_id'] as int?;
          if (_currencyId != null) {
            final cur = await txn.query('currencies', where: 'id = ?', whereArgs: [_currencyId], limit: 1);
            if (cur.isEmpty) {
              lineData['currency_id'] = null;
            }
          }

          // category, group, unit, sub-unit
          final int? _categoryId = lineData['category_id'] as int?;
          int? _groupId = lineData['group_id'] as int?;
          int? _unitId = lineData['unit_id'] as int?;
          int? _subUnitId = lineData['category_sub_unit_id'] as int?;

          // Validate provided group/unit ids
          if (_groupId != null) {
            final g = await txn.query('categories_groups', where: 'id = ?', whereArgs: [_groupId], limit: 1);
            if (g.isEmpty) _groupId = null;
          }
          if (_unitId != null) {
            final u = await txn.query('categories_units', where: 'id = ?', whereArgs: [_unitId], limit: 1);
            if (u.isEmpty) _unitId = null;
          }

          // Try derive group/unit from category if missing
          int? validCategoryId = _categoryId;
          if (_categoryId != null) {
            final cat = await txn.query('categories', where: 'id = ?', whereArgs: [_categoryId], limit: 1);
            if (cat.isNotEmpty) {
              if (_groupId == null) {
                final cg = cat.first['group_id'] as int?;
                if (cg != null) {
                  final g2 = await txn.query('categories_groups', where: 'id = ?', whereArgs: [cg], limit: 1);
                  if (g2.isNotEmpty) {
                    _groupId = cg;
                  }
                }
              }
              if (_unitId == null) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query('categories_units', where: 'id = ?', whereArgs: [cu], limit: 1);
                  if (u2.isNotEmpty) {
                    _unitId = cu;
                  }
                }
              }
            } else {
              // Provided category_id doesn't exist; null it to avoid FK violation (it's nullable in schema)
              validCategoryId = null;
            }
          }

          // If still no valid group_id, ensure or create a default
          if (_groupId == null) {
            final anyGroup = await txn.query('categories_groups', limit: 1);
            if (anyGroup.isEmpty) {
              final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              await txn.insert('categories_groups', {
                'id': 1,
                'name': 'افتراضي',
                'is_active': 1,
                'creation_time': nowSec,
                'last_modification_time': nowSec,
              });
              _groupId = 1;
            } else {
              _groupId = anyGroup.first['id'] as int;
            }
          }

          // If still no valid unit_id, ensure or create a default
          if (_unitId == null) {
            // Try derive from category if exists
            if (_categoryId != null) {
              final cat = await txn.query('categories', where: 'id = ?', whereArgs: [_categoryId], limit: 1);
              if (cat.isNotEmpty) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query('categories_units', where: 'id = ?', whereArgs: [cu], limit: 1);
                  if (u2.isNotEmpty) {
                    _unitId = cu;
                  }
                }
              }
            }
            if (_unitId == null) {
              final anyUnit = await txn.query('categories_units', limit: 1);
              if (anyUnit.isEmpty) {
                final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                await txn.insert('categories_units', {
                  'id': 1,
                  'name': 'وحدة',
                  'short': 'قطعة',
                  'is_active': 1,
                  'creation_time': nowSec,
                  'last_modification_time': nowSec,
                });
                _unitId = 1;
              } else {
                _unitId = anyUnit.first['id'] as int;
              }
            }
          }

          // Ensure category_sub_unit exists for this category (or create a default even without category)
          if (_subUnitId != null) {
            final s = await txn.query('category_sub_units', where: 'id = ?', whereArgs: [_subUnitId], limit: 1);
            if (s.isEmpty) _subUnitId = null;
          }
          if (_subUnitId == null) {
            if (validCategoryId != null) {
              final main = await txn.query('category_sub_units',
                  where: 'category_id = ? AND is_main_unit = 1', whereArgs: [validCategoryId], limit: 1);
              if (main.isNotEmpty) {
                _subUnitId = main.first['id'] as int;
              } else {
                final any = await txn.query('category_sub_units', where: 'category_id = ?', whereArgs: [validCategoryId], limit: 1);
                if (any.isNotEmpty) {
                  _subUnitId = any.first['id'] as int;
                }
              }
            }
            if (_subUnitId == null) {
              // No sub-unit found with or without category; create a default one (category_id can be NULL)
              final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final insertedId = await txn.insert('category_sub_units', {
                'packaging': 1,
                'is_active': 1,
                'is_main_unit': 1,
                'category_id': validCategoryId, // may be null
                'unit_id': _unitId,
                'conversion_rate': 1.0,
                'creation_time': nowSec,
                'last_modification_time': nowSec,
              });
              _subUnitId = insertedId;
            }
          }

          // Ensure valid stock_id for the line (fallback to header's stock_id)
          int? _lineStockId = lineData['stock_id'] as int?;
          if (_lineStockId != null) {
            final st = await txn.query('stocks', where: 'id = ?', whereArgs: [_lineStockId], limit: 1);
            if (st.isEmpty) _lineStockId = null;
          }
          _lineStockId ??= invoiceData['stock_id'] as int?;
          if (_lineStockId == null) {
            _lineStockId = await _ensureStock(null);
          }

          // Ensure valid customer_id for the line (fallback to header's customer_id)
          int? _lineCustomerId = lineData['customer_id'] as int?;
          if (_lineCustomerId != null) {
            final c = await txn.query('customers', where: 'id = ?', whereArgs: [_lineCustomerId], limit: 1);
            if (c.isEmpty) _lineCustomerId = null;
          }
          _lineCustomerId ??= invoiceData['customer_id'] as int?;
          _lineCustomerId ??= 1;

          // Write back ensured values
          lineData['category_id'] = validCategoryId; // null if invalid
          lineData['group_id'] = _groupId;
          lineData['unit_id'] = _unitId;
          lineData['category_sub_unit_id'] = _subUnitId;
          lineData['stock_id'] = _lineStockId;
          lineData['customer_id'] = _lineCustomerId;

          await txn.insert(
            _linesTable,
            lineData,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        return invoiceId;
      });
    } catch (e) {
      throw LocalStorageException('Failed to insert invoice: ${e.toString()}');
    }
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) {
      throw LocalStorageException('Invoice id is required for update');
    }
    try {
      await database.transaction((txn) async {
        final count = await txn.update(
          _invoicesTable,
          invoice.toJson(),
          where: 'id = ?',
          whereArgs: [invoice.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        if (count == 0) {
          throw LocalStorageException(
            'Invoice with id ${invoice.id} was not found',
          );
        }
        await txn.delete(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final line in invoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: invoice.id!),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
    } catch (e) {
      throw LocalStorageException('Failed to update invoice: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteInvoice(int id) async {
    try {
      final deleted = await database.delete(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted == 0) {
        throw LocalStorageException('Invoice with id $id not found');
      }
    } catch (e) {
      throw LocalStorageException('Failed to delete invoice: ${e.toString()}');
    }
  }

  @override
  Future<List<InvoiceModel>> searchInvoices(String query) async {
    try {
      final rows = await database.query(
        _invoicesTable,
        where: 'number LIKE ? OR u_no LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC, id DESC',
      );
      final List<InvoiceModel> results = [];
      for (final h in rows) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException('Failed to search invoices: ${e.toString()}');
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByType(int invoiceType) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'invoice_type = ?',
        whereArgs: [invoiceType],
        orderBy: 'date DESC, id DESC',
      );
      
      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get invoices by type: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByCustomer(int customerId) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC, id DESC',
      );
      
      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get invoices by customer: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getQuotations() async {
    return await getInvoicesByType(3); // InvoiceType.quotation = 3
  }

  @override
  Future<List<InvoiceModel>> getOpenQuotations() async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'invoice_type = ? AND (next_invoice_id IS NULL OR next_invoice_id = 0)',
        whereArgs: [3], // Quotations that haven't been converted
        orderBy: 'date DESC, id DESC',
      );
      
      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get open quotations: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> convertQuotationToInvoice(
    int quotationId,
    InvoiceModel salesInvoice,
  ) async {
    try {
      return await database.transaction((txn) async {
        // 1. Insert the new sales invoice
        final invoiceId = await txn.insert(
          _invoicesTable,
          salesInvoice.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        
        // 2. Insert invoice lines
        for (final line in salesInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: invoiceId),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        
        // 3. Update the quotation to mark it as converted
        await txn.update(
          _invoicesTable,
          {
            'next_invoice_id': invoiceId,
            'next_invoice_type': 1, // Sales invoice
            'next_invoice_number': salesInvoice.number,
            'payment_status': 4, // Converted status
          },
          where: 'id = ?',
          whereArgs: [quotationId],
        );
        
        return invoiceId;
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to convert quotation: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getReturnInvoices() async {
    return await getInvoicesByType(4); // InvoiceType.salesReturn = 4
  }

  @override
  Future<List<InvoiceModel>> getReturnsByParentInvoice(
    int parentInvoiceId,
  ) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'parent_invoice_id = ? AND invoice_type = ?',
        whereArgs: [parentInvoiceId, 4],
        orderBy: 'date DESC, id DESC',
      );
      
      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get returns by parent: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> createReturnInvoice(
    InvoiceModel returnInvoice,
    int parentInvoiceId,
  ) async {
    try {
      return await database.transaction((txn) async {
        // 1. Insert the return invoice
        final returnId = await txn.insert(
          _invoicesTable,
          returnInvoice.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        
        // 2. Insert return invoice lines
        for (final line in returnInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: returnId),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          
          // 3. Update inventory - increase stock quantity for returns
          await txn.rawUpdate(
            'UPDATE categories SET quantity = quantity + ? WHERE id = ?',
            [line.quantity, line.categoryId],
          );
        }
        
        // 4. Update parent invoice to reference this return
        await txn.update(
          _invoicesTable,
          {
            'next_invoice_id': returnId,
            'next_invoice_type': 4, // Return invoice
            'next_invoice_number': returnInvoice.number,
          },
          where: 'id = ?',
          whereArgs: [parentInvoiceId],
        );
        
        // 5. Update customer balance (reduce receivable)
        // The return amount should be deducted from what customer owes
        await txn.rawUpdate(
          'UPDATE customers SET current_balance = current_balance - ? WHERE id = ?',
          [returnInvoice.finalAmt ?? returnInvoice.amount, returnInvoice.customerId],
        );
        
        return returnId;
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to create return invoice: ${e.toString()}',
      );
    }
  }
}
