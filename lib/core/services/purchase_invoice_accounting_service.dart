import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Comprehensive service for processing purchase invoices
/// Handles: Inventory updates, average cost calculation, VAT, and journal entries
class PurchaseInvoiceAccountingService {
  final DatabaseService _databaseService;

  PurchaseInvoiceAccountingService(this._databaseService);

  // Table names
  static const String _invoicesTable = 'invoices';
  static const String _invoiceLinesTable = 'invoice_lines';
  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalLinesTable = 'journal_entry_lines';
  static const String _accountsTable = 'accounts';
  static const String _warehouseStocksTable = 'warehouse_stocks';
  static const String _stockMovementsTable = 'stock_movements';
  static const String _customersTable = 'customers'; // Used for suppliers too

  /// Process a purchase invoice with full accounting and inventory integration
  Future<Either<Failure, PurchaseInvoiceResult>> processPurchaseInvoice({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> invoiceLines,
  }) async {
    try {
      final db = await _databaseService.database;

      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Extract invoice data
        final invoiceNumber = invoiceData['number'] as String? ?? 'PI-$now';
        final supplierId = invoiceData['customer_id'] as int? ?? 1;
        final warehouseId = invoiceData['stock_id'] as int? ?? 1;
        final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;
        
        // Calculate totals
        final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
        final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
        final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
        final otherFees = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;
        final total = (invoiceData['final_amt'] as num?)?.toDouble() ?? 
                      (subtotal - discount + tax + otherFees);

        // 1. Insert the purchase invoice
        invoiceData['creation_time'] = now;
        invoiceData['last_modification_time'] = now;
        invoiceData.remove('id');
        
        final invoiceId = await txn.insert(
          _invoicesTable,
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // 2. Process each line - update inventory and calculate average cost
        double totalInventoryValue = 0.0;
        
        for (final line in invoiceLines) {
          final productId = line['category_id'] as int?;
          final lineWarehouseId = line['stock_id'] as int? ?? warehouseId;
          
          // Get user entered quantity and price
          final qty = (line['quantity'] as num?)?.toDouble() ?? 0.0;
          final price = (line['price'] as num?)?.toDouble() ?? 0.0;
          
          // Use base_quantity for accurate inventory operations (unit conversion)
          // If base_quantity is not provided, assume it's the same as quantity (base unit)
          final baseQty = (line['base_quantity'] as num?)?.toDouble() ?? qty;
          
          // Calculate total cost for the line based on user input (Quantity * Unit Price)
          final lineTotalCost = qty * price;
          
          // Calculate cost per base unit
          // This is critical: Inventory tracks base units, so we need the cost of 1 base unit
          final baseUnitCost = baseQty > 0 ? lineTotalCost / baseQty : 0.0;
          
          // Insert invoice line
          line['invoice_id'] = invoiceId;
          line.remove('id');
          await txn.insert(_invoiceLinesTable, line);
          
          if (productId != null && baseQty > 0) {
            // Update inventory with weighted average cost - use base_quantity and base_unit_cost
            await _updateInventoryWithAverageCost(
              txn: txn,
              productId: productId,
              warehouseId: lineWarehouseId,
              quantity: baseQty, // Use converted base quantity
              unitCost: baseUnitCost, // Use calculated base unit cost
              totalCost: lineTotalCost,
              referenceType: 'purchase_invoice',
              referenceId: invoiceId,
              referenceNumber: invoiceNumber,
              now: now,
            );
            
            totalInventoryValue += lineTotalCost;
          }
        }

        // 3. Create journal entry
        final journalEntryId = await _createPurchaseJournalEntry(
          txn: txn,
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          supplierId: supplierId,
          isCredit: isCredit,
          subtotal: subtotal,
          discount: discount,
          tax: tax,
          otherFees: otherFees,
          total: total,
          inventoryValue: totalInventoryValue,
          now: now,
          statement: invoiceData['statement'] as String? ?? 'فاتورة مشتريات',
        );

        // 4. Update supplier balance (for credit purchases)
        if (isCredit) {
          await txn.rawUpdate(
            'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) + ? WHERE id = ?',
            [total, supplierId],
          );
        }

        return Right(PurchaseInvoiceResult(
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          journalEntryId: journalEntryId,
          totalAmount: total,
          inventoryValue: totalInventoryValue,
        ));
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في معالجة فاتورة المشتريات: ${e.toString()}'));
    }
  }

  /// Update inventory with weighted average cost calculation
  Future<void> _updateInventoryWithAverageCost({
    required Transaction txn,
    required int productId,
    required int warehouseId,
    required double quantity,
    required double unitCost,
    required double totalCost,
    required String referenceType,
    required int referenceId,
    required String referenceNumber,
    required int now,
  }) async {
    // Get current stock
    final stockResult = await txn.query(
      _warehouseStocksTable,
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [productId, warehouseId],
      limit: 1,
    );

    double currentQty = 0.0;
    double currentAvgCost = 0.0;
    double newQty = quantity;
    double newAvgCost = unitCost;

    if (stockResult.isNotEmpty) {
      currentQty = (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;
      currentAvgCost = (stockResult.first['avg_cost'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate weighted average cost
      // New Avg = (Current Qty × Current Avg + New Qty × New Cost) / (Current Qty + New Qty)
      // Note: New Cost here is the Base Unit Cost
      final totalQty = currentQty + quantity;
      
      // Calculate total value
      final currentValue = currentQty * currentAvgCost;
      final newValue = totalCost; // This is (quantity * unitCost) passed from caller
      
      if (totalQty > 0) {
        newAvgCost = (currentValue + newValue) / totalQty;
      }
      newQty = totalQty;

      // Update existing stock
      await txn.update(
        _warehouseStocksTable,
        {
          'quantity': newQty,
          'avg_cost': newAvgCost,
          'last_cost': unitCost,
          'last_modification_time': now,
        },
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, warehouseId],
      );
    } else {
      // Insert new stock record
      await txn.insert(
        _warehouseStocksTable,
        {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': newQty,
          'avg_cost': newAvgCost,
          'last_cost': unitCost,
          'creation_time': now,
          'last_modification_time': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Record stock movement
    try {
      await txn.insert(
        _stockMovementsTable,
        {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'movement_type': 'purchase',
          'quantity': quantity, // Positive for purchase
          'unit_cost': unitCost,
          'total_cost': totalCost,
          'avg_cost_after': newAvgCost,
          'balance_after': newQty,
          'reference_type': referenceType,
          'reference_id': referenceId,
          'reference_number': referenceNumber,
          'creation_time': now,
        },
      );
    } catch (_) {
      // Ignore if stock_movements table doesn't exist
    }
  }

  /// Create journal entry for purchase invoice
  Future<int> _createPurchaseJournalEntry({
    required Transaction txn,
    required int invoiceId,
    required String invoiceNumber,
    required int supplierId,
    required bool isCredit,
    required double subtotal,
    required double discount,
    required double tax,
    required double otherFees,
    required double total,
    required double inventoryValue,
    required int now,
    required String statement,
  }) async {
    // Resolve account IDs
    final inventoryAccountId = await _resolveAccountId(txn, 'المخزون', 1180);
    final inputVatAccountId = await _resolveAccountId(txn, 'ضريبة مدخلات', 1170);
    final discountEarnedAccountId = await _resolveAccountId(txn, 'الخصم المكتسب', 4140);
    final cashAccountId = await _resolveAccountId(txn, 'الصناديق', 1110);
    final supplierAccountId = await _resolveSupplierAccountId(txn, supplierId);

    final lines = <Map<String, dynamic>>[];

    // Debit: Inventory (at cost, excluding VAT)
    if (inventoryValue > 0) {
      lines.add({
        'account_id': inventoryAccountId,
        'debit_amount': _round(inventoryValue),
        'credit_amount': 0.0,
        'description': 'شراء مخزون - $invoiceNumber',
      });
    }

    // Debit: Other fees (if any)
    if (otherFees > 0) {
      // Add to inventory cost or expense
      lines.add({
        'account_id': inventoryAccountId,
        'debit_amount': _round(otherFees),
        'credit_amount': 0.0,
        'description': 'مصاريف شحن/إضافية - $invoiceNumber',
      });
    }

    // Debit: Input VAT (recoverable)
    if (tax > 0) {
      lines.add({
        'account_id': inputVatAccountId,
        'debit_amount': _round(tax),
        'credit_amount': 0.0,
        'description': 'ضريبة مدخلات قابلة للاسترداد - $invoiceNumber',
      });
    }

    // Credit: Discount earned
    if (discount > 0) {
      lines.add({
        'account_id': discountEarnedAccountId,
        'debit_amount': 0.0,
        'credit_amount': _round(discount),
        'description': 'خصم مكتسب - $invoiceNumber',
      });
    }

    // Credit: Accounts Payable (credit) or Cash (cash purchase)
    lines.add({
      'account_id': isCredit ? supplierAccountId : cashAccountId,
      'debit_amount': 0.0,
      'credit_amount': _round(total),
      'description': isCredit ? 'ذمم موردين - $invoiceNumber' : 'دفع نقدي - $invoiceNumber',
    });

    // Calculate totals and verify balance
    final totalDebit = lines.fold<double>(
      0.0, (sum, l) => sum + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0));
    final totalCredit = lines.fold<double>(
      0.0, (sum, l) => sum + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0));

    // Balance adjustment if needed (due to rounding)
    final diff = totalDebit - totalCredit;
    if (diff.abs() > 0.01) {
      // Add adjustment line
      if (diff > 0) {
        lines.last['credit_amount'] = (lines.last['credit_amount'] as double) + diff;
      } else {
        lines.first['debit_amount'] = (lines.first['debit_amount'] as double) - diff;
      }
    }

    // Generate journal number
    final journalNumber = await _nextJournalNumber(txn, 'PI');

    // Insert journal entry
    final journalEntryId = await txn.insert(
      _journalEntriesTable,
      {
        'number': journalNumber,
        'entry_date': now,
        'description': 'قيد مشتريات - $invoiceNumber',
        'reference_type': 'purchase_invoice',
        'reference_id': invoiceId,
        'reference_number': invoiceNumber,
        'notes': statement,
        'status': 1,
        'is_posted': 1,
        'total_debit': totalDebit,
        'total_credit': totalCredit,
        'difference': 0.0,
        'creation_time': now,
        'last_modification_time': now,
      },
    );

    // Insert journal lines
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final accountId = line['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (line['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (line['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'debit_amount': debit,
        'credit_amount': credit,
        'description': line['description'],
      });

      // Update account balance
      await txn.rawUpdate(
        'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
        [debit - credit, accountId],
      );
    }

    return journalEntryId;
  }

  // ==================== Helper Methods ====================
  
  /// Round to 2 decimal places
  double _round(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  Future<int> _resolveAccountId(Transaction txn, String label, int defaultId) async {
    // Try to find by name first
    var result = await txn.query(
      _accountsTable,
      columns: ['id'],
      where: 'name LIKE ?',
      whereArgs: ['%$label%'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    
    // Try by c_id
    result = await txn.query(
      _accountsTable,
      columns: ['id'],
      where: 'c_id = ?',
      whereArgs: [defaultId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    
    return defaultId;
  }

  Future<int> _resolveSupplierAccountId(Transaction txn, int supplierId) async {
    // Try to get supplier's linked account
    final supplier = await txn.query(
      _customersTable,
      columns: ['account_id'],
      where: 'id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    
    if (supplier.isNotEmpty && supplier.first['account_id'] != null) {
      return supplier.first['account_id'] as int;
    }
    
    // Fall back to suppliers parent account
    return await _resolveAccountId(txn, 'الموردون', 2110);
  }

  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
    final result = await txn.query(
      _accountsTable,
      columns: ['code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return {'code': result.first['code'] ?? '', 'name': result.first['name'] ?? ''};
    }
    return {'code': '', 'name': ''};
  }

  Future<String> _nextJournalNumber(Transaction txn, String prefix) async {
    final result = await txn.rawQuery(
      "SELECT COALESCE(MAX(CAST(SUBSTR(number, ${prefix.length + 2}) AS INTEGER)), 0) + 1 as next "
      "FROM journal_entries WHERE number LIKE '$prefix-%'",
    );
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }
}

/// Result of purchase invoice processing
class PurchaseInvoiceResult {
  final int invoiceId;
  final String invoiceNumber;
  final int journalEntryId;
  final double totalAmount;
  final double inventoryValue;

  PurchaseInvoiceResult({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.journalEntryId,
    required this.totalAmount,
    required this.inventoryValue,
  });
}
