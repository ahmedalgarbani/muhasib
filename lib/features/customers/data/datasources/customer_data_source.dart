import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/customers/data/models/customer_model.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'dart:convert';

abstract class CustomerDataSource {
  Future<List<CustomerModel>> getCustomers({bool includeInactive = false});
  Future<List<CustomerModel>> getSuppliers({bool includeInactive = false});
  Future<CustomerModel> getCustomerById(int customerId);
  Future<CustomerModel> addCustomer({
    required String name,
    required int type,
    String? contact,
    String? address,
    double creditLimit = 0.0,
    double openingBalance = 0.0,
  });
  Future<CustomerModel> updateCustomer({
    required int customerId,
    String? name,
    String? contact,
    String? address,
    double? creditLimit,
    bool? isActive,
  });
  Future<void> updateCustomerBalance({
    required int customerId,
    required double newBalance,
  });
  Future<void> deleteCustomer(int customerId);
  Future<List<CustomerModel>> searchCustomers({
    required String query,
    int? type,
  });
  Future<Map<String, dynamic>> getCustomerSummary(int customerId);
}

class CustomerDataSourceImpl implements CustomerDataSource {
  final DatabaseService databaseService;

  CustomerDataSourceImpl({required this.databaseService});

  /// Helper method to create a default parent account when no account_connect is configured
  Future<int> _createDefaultParentAccount(
    dynamic txn,
    int cId,
    String code,
    String name,
    int accountType,
  ) async {
    return await txn.insert('accounts', {
      'c_id': cId,
      'code': code,
      'name': name,
      'is_master': 1,
      'type': accountType,
      'national': 1,
      'is_active': 1,
      'allow_update_delete': 0,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  @override
  Future<List<CustomerModel>> getCustomers({bool includeInactive = false}) async {
    final db = await databaseService.database;
    
    final String activeCondition = includeInactive ? '' : ' AND c.is_active = 1';
    
    final results = await db.rawQuery('''
      SELECT 
        c.*,
        a.balance as account_balance
      FROM customers c
      LEFT JOIN accounts a ON c.account_id = a.id
      WHERE c.type = 1$activeCondition
      ORDER BY c.name
    ''');

    return results.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<List<CustomerModel>> getSuppliers({bool includeInactive = false}) async {
    final db = await databaseService.database;
    
    final String activeCondition = includeInactive ? '' : ' AND c.is_active = 1';
    
    final results = await db.rawQuery('''
      SELECT 
        c.*,
        a.balance as account_balance
      FROM customers c
      LEFT JOIN accounts a ON c.account_id = a.id
      WHERE c.type = 2$activeCondition
      ORDER BY c.name
    ''');

    return results.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<CustomerModel> getCustomerById(int customerId) async {
    final db = await databaseService.database;
    
    final results = await db.rawQuery('''
      SELECT 
        c.*,
        a.balance as account_balance
      FROM customers c
      LEFT JOIN accounts a ON c.account_id = a.id
      WHERE c.id = ?
    ''', [customerId]);

    if (results.isEmpty) {
      throw Exception('Customer not found');
    }

    return CustomerModel.fromMap(results.first);
  }

  @override
  Future<CustomerModel> addCustomer({
    required String name,
    required int type,
    String? contact,
    String? address,
    double creditLimit = 0.0,
    double openingBalance = 0.0,
  }) async {
    final db = await databaseService.database;
    
    late int customerId;
    
    await db.transaction((txn) async {
      // Get parent account from account_connects table dynamically
      // Type mapping: customer type 1 -> account_connect_type 2, supplier type 2 -> account_connect_type 3
      final accountConnectType = type == 1 ? AccountConnectTypes.customers : AccountConnectTypes.suppliers;
      final accountType = type == 1 ? 1 : 2; // 1=Assets for customers, 2=Liabilities for suppliers
      
      // Fallback names if no account_connect is found
      final defaultParentName = type == 1 ? 'العملاء' : 'الموردين';
      final defaultParentCode = type == 1 ? DefaultAccountIds.customers.toString() : DefaultAccountIds.suppliers.toString();
      final defaultParentCId = type == 1 ? DefaultAccountIds.customers : DefaultAccountIds.suppliers;
      
      int parentId;
      int parentCId;
      
      // Try to get linked account from account_connects
      final accountConnect = await txn.query(
        'account_connects',
        where: 'account_connect_type = ?',
        whereArgs: [accountConnectType],
        limit: 1,
      );
      
      if (accountConnect.isNotEmpty && accountConnect.first['c_id'] != null) {
        // Found a linked account, use it
        final linkedCId = accountConnect.first['c_id'] as int;
        
        final linkedAccount = await txn.query(
          'accounts',
          where: 'c_id = ?',
          whereArgs: [linkedCId],
          limit: 1,
        );
        
        if (linkedAccount.isNotEmpty) {
          parentId = linkedAccount.first['id'] as int;
          parentCId = linkedAccount.first['c_id'] as int;
        } else {
          // Linked c_id not found in accounts, create parent account with defaults
          parentId = await _createDefaultParentAccount(
            txn, defaultParentCId, defaultParentCode, defaultParentName, accountType,
          );
          parentCId = defaultParentCId;
        }
      } else {
        // No account_connect found, try to find existing parent account by name
        final parentAccount = await txn.query(
          'accounts',
          where: 'name = ? AND is_master = 1',
          whereArgs: [defaultParentName],
          limit: 1,
        );

        if (parentAccount.isEmpty) {
          // Create parent account if it doesn't exist
          parentId = await _createDefaultParentAccount(
            txn, defaultParentCId, defaultParentCode, defaultParentName, accountType,
          );
          parentCId = defaultParentCId;
        } else {
          parentId = parentAccount.first['id'] as int;
          parentCId = parentAccount.first['c_id'] as int;
        }
      }

      // Generate unique code for the customer/supplier account
      // Use parent c_id * 100 as base for child codes
      final startCode = parentCId * 100;
      final lastAccount = await txn.rawQuery(
        'SELECT MAX(CAST(code AS INTEGER)) as max_code FROM accounts WHERE master_id = ?',
        [parentId],
      );

      int nextCode = startCode + 1;
      if (lastAccount.isNotEmpty && lastAccount.first['max_code'] != null) {
        final maxCode = lastAccount.first['max_code'] as int;
        if (maxCode >= startCode) {
          nextCode = maxCode + 1;
        }
      }

      // Opening balance in debit-normal convention (the single source of truth):
      // Customer: + = owes business (debit/عليه), - = credit balance (له)
      // Supplier: + = advance paid to supplier (debit/عليه), - = business owes supplier (credit/له)
      final debitNormalBalance = type == 1 ? openingBalance : -openingBalance;

      // Create account for the customer/supplier.
      // The account starts at zero; the opening-balance journal entry below
      // posts the balance (journal is the only source of account balances).
      final accountId = await txn.insert('accounts', {
        'c_id': nextCode,
        'code': nextCode.toString(),
        'name': name,
        'is_master': 0,
        'master_id': parentId,
        'master_c_id': parentCId,
        'type': accountType,
        'national': 1,
        'statement': type == 1 ? 'حساب العميل: $name' : 'حساب المورد: $name',
        'is_active': 1,
        'allow_update_delete': 1,
        'balance': 0.0,
        'local_balance': 0.0,
        'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      // Ensure classifications table has data
      final classificationsCount = await txn.rawQuery(
        'SELECT COUNT(*) as count FROM classifications WHERE type = ?',
        [type],
      );
      
      if ((classificationsCount.first['count'] as int) == 0) {
        await txn.insert('classifications', {
          'id': type,
          'name': type == 1 ? 'عملاء عاديين' : 'موردين عاديين',
          'singler_name': type == 1 ? 'عميل' : 'مورد',
          'order': 1,
          'type': type,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }

      // Create the customer/supplier record
      customerId = await txn.insert('customers', 
        CustomerModel.toInsertMap(
          name: name,
          type: type,
          contact: contact,
          address: address,
          creditLimit: creditLimit,
          currentBalance: debitNormalBalance,
          accountId: accountId,
          classificationId: type,
        ),
      );

      // Post the opening balance journal entry (updates account balances)
      if (debitNormalBalance.abs() > 0.0001) {
        await _createOpeningBalanceEntry(
          txn: txn,
          accountId: accountId,
          accountName: name,
          partyDebitDelta: debitNormalBalance,
          type: type,
        );
      }
    });

    return getCustomerById(customerId);
  }

  @override
  Future<CustomerModel> updateCustomer({
    required int customerId,
    String? name,
    String? contact,
    String? address,
    double? creditLimit,
    bool? isActive,
  }) async {
    final db = await databaseService.database;
    
    final Map<String, dynamic> updateData = {
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    
    if (name != null) updateData['name'] = name;
    if (contact != null) updateData['contact'] = contact;
    if (creditLimit != null) updateData['credit_limit'] = creditLimit;
    if (isActive != null) updateData['is_active'] = isActive ? 1 : 0;
    
    await db.transaction((txn) async {
      if (address != null) {
        // customers table has no `address` column; store it in extra_properties
        final rows = await txn.query(
          'customers',
          columns: ['extra_properties'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        Map<String, dynamic> extra = {};
        final current = rows.isNotEmpty ? rows.first['extra_properties'] as String? : null;
        if (current != null && current.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(current);
            if (decoded is Map<String, dynamic>) {
              extra = decoded;
            } else if (decoded is Map) {
              extra = decoded.map((k, v) => MapEntry(k.toString(), v));
            }
          } catch (_) {}
        }
        extra['address'] = address;
        updateData['extra_properties'] = jsonEncode(extra);
      }

      // Update customer record
      await txn.update(
        'customers',
        updateData,
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      // If name changed, update the account name too
      if (name != null) {
        final customer = await txn.query(
          'customers',
          columns: ['account_id', 'type'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        
        if (customer.isNotEmpty) {
          final accountId = customer.first['account_id'] as int?;
          final type = customer.first['type'] as int;
          
          if (accountId != null) {
            await txn.update(
              'accounts',
              {
                'name': name,
                'statement': type == 1 ? 'حساب العميل: $name' : 'حساب المورد: $name',
                'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              },
              where: 'id = ?',
              whereArgs: [accountId],
            );
          }
        }
      }
    });
    
    return getCustomerById(customerId);
  }

  @override
  Future<void> updateCustomerBalance({
    required int customerId,
    required double newBalance,
  }) async {
    final db = await databaseService.database;
    
    await db.transaction((txn) async {
      // Update customer balance
      await txn.update(
        'customers',
        {
          'current_balance': newBalance,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      // Update account balance
      final customer = await txn.query(
        'customers',
        columns: ['account_id'],
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      
      if (customer.isNotEmpty) {
        final accountId = customer.first['account_id'] as int?;
        
        if (accountId != null) {
          await txn.update(
            'accounts',
            {
              'balance': newBalance,
              'local_balance': newBalance,
              'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            },
            where: 'id = ?',
            whereArgs: [accountId],
          );
        }
      }
    });
  }

  @override
  Future<void> deleteCustomer(int customerId) async {
    final db = await databaseService.database;
    
    // Soft delete - just mark as inactive
    await db.update(
      'customers',
      {
        'is_active': 0,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  @override
  Future<List<CustomerModel>> searchCustomers({
    required String query,
    int? type,
  }) async {
    final db = await databaseService.database;
    
    String whereClause = 'c.name LIKE ? OR c.contact LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];
    
    if (type != null) {
      whereClause += ' AND c.type = ?';
      whereArgs.add(type);
    }
    
    final results = await db.rawQuery('''
      SELECT 
        c.*,
        a.balance as account_balance
      FROM customers c
      LEFT JOIN accounts a ON c.account_id = a.id
      WHERE $whereClause AND c.is_active = 1
      ORDER BY c.name
    ''', whereArgs);

    return results.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<Map<String, dynamic>> getCustomerSummary(int customerId) async {
    final db = await databaseService.database;
    
    // Get customer details
    final customer = await getCustomerById(customerId);
    
    // Get total sales/purchases
    final transactionsSummary = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        SUM(amount) as total_amount,
        MAX(date) as last_transaction_date
      FROM invoices
      WHERE customer_id = ? AND is_deleted = 0
    ''', [customerId]);
    
    // Get unpaid invoices count
    final unpaidInvoices = await db.rawQuery('''
      SELECT COUNT(*) as unpaid_count
      FROM invoices
      WHERE customer_id = ? AND is_deleted = 0 AND payment_status != 1
    ''', [customerId]);
    
    return {
      'customer': customer,
      'total_transactions': transactionsSummary.first['total_transactions'] ?? 0,
      'total_amount': transactionsSummary.first['total_amount'] ?? 0.0,
      'last_transaction_date': transactionsSummary.first['last_transaction_date'],
      'unpaid_invoices': unpaidInvoices.first['unpaid_count'] ?? 0,
      'current_balance': customer.currentBalance,
      'credit_limit': customer.creditLimit,
      'is_over_limit': customer.isOverCreditLimit,
    };
  }

  /// Create and POST the opening balance journal entry for customer/supplier.
  ///
  /// [partyDebitDelta] is debit-normal (debit - credit) for the party account:
  /// - Customer owes money         => positive (Dr customer)
  /// - Customer has credit balance => negative (Cr customer)
  /// - Supplier advance paid       => positive (Dr supplier)
  /// - Business owes supplier      => negative (Cr supplier)
  ///
  /// The journal entry is the single source of truth: it updates the
  /// account balances of both the party account and the opening-balance
  /// account (code 3100).
  Future<void> _createOpeningBalanceEntry({
    required dynamic txn,
    required int accountId,
    required String accountName,
    required double partyDebitDelta,
    required int type,
  }) async {
    final absAmount = partyDebitDelta.abs();
    if (absAmount < 0.0001) return;

    // 1. Get or create Opening Balance account (code 3100)
    final obResults = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['3100'],
      limit: 1,
    );

    int obAccountId;
    if (obResults.isEmpty) {
      // Create Opening Balance account
      obAccountId = await txn.insert('accounts', {
        'c_id': 3100,
        'code': '3100',
        'name': 'أرصدة افتتاحية',
        'is_master': 0,
        'type': 2,  // Equity
        'national': 1,
        'is_active': 1,
        'allow_update_delete': 0,
        'balance': 0.0,
        'local_balance': 0.0,
        'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } else {
      obAccountId = obResults.first['id'] as int;
    }

    final isPartyDebit = partyDebitDelta > 0;
    final partyLabel = type == 1 ? 'عميل' : 'مورد';
    final directionLabel = isPartyDebit ? 'مدين (عليه)' : 'دائن (له)';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 2. Create journal entry (posted)
    final entryId = await txn.insert('journal_entries', {
      'number': 'OB-${DateTime.now().millisecondsSinceEpoch}',
      'entry_date': now,
      'description': 'رصيد افتتاحي $directionLabel - $partyLabel: $accountName',
      'reference_type': 'opening_balance',
      'reference_number': accountName,
      'reference_id': accountId,
      'total_debit': absAmount,
      'total_credit': absAmount,
      'difference': 0.0,
      'status': 2,
      'is_posted': 1,
      'creation_time': now,
      'last_modification_time': now,
    });

    // 3. Insert journal entry lines
    if (isPartyDebit) {
      // Line 1: Debit Party Account
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 1,
        'account_id': accountId,
        'account_name': accountName,
        'currency_code': 'YER',
        'debit_amount': absAmount,
        'credit_amount': 0.0,
      });

      // Line 2: Credit Opening Balance
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 2,
        'account_id': obAccountId,
        'account_code': '3100',
        'account_name': 'أرصدة افتتاحية',
        'currency_code': 'YER',
        'debit_amount': 0.0,
        'credit_amount': absAmount,
      });
    } else {
      // Line 1: Debit Opening Balance
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 1,
        'account_id': obAccountId,
        'account_code': '3100',
        'account_name': 'أرصدة افتتاحية',
        'currency_code': 'YER',
        'debit_amount': absAmount,
        'credit_amount': 0.0,
      });

      // Line 2: Credit Party Account
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 2,
        'account_id': accountId,
        'account_name': accountName,
        'currency_code': 'YER',
        'debit_amount': 0.0,
        'credit_amount': absAmount,
      });
    }

    // 4. Update account balances (debit-normal) — journal is the source
    await _applyAccountBalanceDelta(txn, accountId, partyDebitDelta);
    await _applyAccountBalanceDelta(txn, obAccountId, -partyDebitDelta);

    print('✅ Created opening balance entry for $accountName: $partyDebitDelta ($directionLabel)');
  }

  /// Applies a debit-normal delta to an account balance
  Future<void> _applyAccountBalanceDelta(
    dynamic txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = current + delta;
    await txn.update(
      'accounts',
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
