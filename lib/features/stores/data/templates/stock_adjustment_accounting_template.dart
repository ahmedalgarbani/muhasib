import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:intl/intl.dart';

/// Stock Adjustment Accounting Template
/// Creates proper journal entries for inventory adjustments
class StockAdjustmentAccountingTemplate {
  final DatabaseService _database;
  final AccountConfigService _accountConfig;

  StockAdjustmentAccountingTemplate(this._database, this._accountConfig);

  /// Create journal entry for stock adjustment
  Future<void> createAdjustmentJournalEntry({
    required int adjustmentId,
    required int productId,
    required String productName,
    required int warehouseId,
    required String warehouseName,
    required double quantityDifference,
    required double unitCost,
    required String reason,
    required DateTime adjustmentDate,
  }) async {
    try {
      final db = await _database.database;
      final config = await _accountConfig.getSalesAccountConfig();
      
      final adjustmentValue = quantityDifference * unitCost;
      
      if (adjustmentValue.abs() < 0.01) {
        // No significant value difference, skip journal entry
        return;
      }

      await db.transaction((txn) async {
        // Create journal entry
        final journalNumber = 'SA-${DateFormat('yyyyMMddHHmmss').format(adjustmentDate)}';
        
        // Unified chart: use 4200/5200 same as live settlements (not 4900/5900)
        // status 2 / is_posted 1 so reports include these journals
        final entryId = await txn.insert('journal_entries', {
          'number': journalNumber,
          'entry_date': adjustmentDate.millisecondsSinceEpoch ~/ 1000,
          'description': 'تسوية مخزون - $productName ($warehouseName)',
          'reference_type': 'stock_adjustment',
          'reference_id': adjustmentId,
          'reference_number': adjustmentId.toString(),
          'total_debit': adjustmentValue.abs(),
          'total_credit': adjustmentValue.abs(),
          'difference': 0.0,
          'status': 2,
          'is_posted': 1,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        if (quantityDifference > 0) {
          // Positive adjustment (found more inventory)
          // Dr. Inventory (Asset)
          // Cr. Inventory Adjustment Income (Other Income)
          
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': entryId,
            'line_number': 1,
            'account_id': config.inventoryAccountId,
            'account_name': 'المخزون',
            'currency_code': await _getBaseCurrency(),
            'debit_amount': adjustmentValue,
            'credit_amount': 0.0,
            'description': 'زيادة مخزون - $productName',
          });

          // Get or create Inventory Adjustment Income account
          final incomeAccountId = await _getOrCreateAdjustmentIncomeAccount(txn);
          
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': entryId,
            'line_number': 2,
            'account_id': incomeAccountId,
            'account_name': 'إيرادات تسوية المخزون',
            'currency_code': await _getBaseCurrency(),
            'debit_amount': 0.0,
            'credit_amount': adjustmentValue,
            'description': 'إيراد من زيادة المخزون - $productName',
          });
        } else {
          // Negative adjustment (inventory shortage/loss)
          // Dr. Inventory Loss (Expense)
          // Cr. Inventory (Asset)
          
          // Get or create Inventory Loss account
          final lossAccountId = await _getOrCreateInventoryLossAccount(txn);
          
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': entryId,
            'line_number': 1,
            'account_id': lossAccountId,
            'account_name': 'خسائر المخزون',
            'currency_code': await _getBaseCurrency(),
            'debit_amount': adjustmentValue.abs(),
            'credit_amount': 0.0,
            'description': 'خسارة مخزون - $productName ($reason)',
          });

          await txn.insert('journal_entry_lines', {
            'journal_entry_id': entryId,
            'line_number': 2,
            'account_id': config.inventoryAccountId,
            'account_name': 'المخزون',
            'currency_code': await _getBaseCurrency(),
            'debit_amount': 0.0,
            'credit_amount': adjustmentValue.abs(),
            'description': 'تقليل مخزون - $productName',
          });
        }

        print('✅ Created stock adjustment journal entry: $journalNumber');
      });
    } catch (e) {
      print('⚠️ Failed to create stock adjustment journal entry: $e');
      rethrow;
    }
  }

  /// Get or create Inventory Adjustment Income account — unified to 4200 (not 4900)
  Future<int> _getOrCreateAdjustmentIncomeAccount(dynamic txn) async {
    // Prefer unified code 4200
    var existing = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['4200'],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    // Fallback: legacy 4900 if already seeded
    existing = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['4900'],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await txn.insert('accounts', {
      'c_id': 4200,
      'code': '4200',
      'name': 'إيرادات تسوية المخزون',
      'is_master': 0,
      'type': 4,
      'national': 1,
      'is_active': 1,
      'allow_update_delete': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  /// Get or create Inventory Loss account — unified to 5200 (not 5900)
  Future<int> _getOrCreateInventoryLossAccount(dynamic txn) async {
    var existing = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['5200'],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    existing = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['5900'],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await txn.insert('accounts', {
      'c_id': 5200,
      'code': '5200',
      'name': 'خسائر تسوية المخزون',
      'is_master': 0,
      'type': 5,
      'national': 1,
      'is_active': 1,
      'allow_update_delete': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  /// Get base currency code
  Future<String> _getBaseCurrency() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'currencies',
        where: 'is_local_currency = ?',
        whereArgs: [1],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['code'] as String? ?? 'YER';
      }
      
      return 'YER'; // Default to YER
    } catch (e) {
      return 'YER'; // Fallback
    }
  }
}
