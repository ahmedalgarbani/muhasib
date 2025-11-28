import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

part 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final DatabaseService _databaseService;

  CustomersCubit(this._databaseService) : super(CustomersInitial());

  Future<void> loadCustomers() async {
    try {
      emit(CustomersLoading());

      final db = await _databaseService.database;

      // Query customers with their account information
      final customersData = await db.rawQuery('''
        SELECT 
          c.id,
          c.name,
          c.type,
          c.contact,
          c.is_active,
          c.credit_limit,
          c.current_balance,
          a.balance as account_balance
        FROM customers c
        LEFT JOIN accounts a ON c.account_id = a.id
        WHERE c.is_active = 1
        ORDER BY c.name
      ''');

      final customers = customersData.map((data) {
        return Customer(
          id: data['id'].toString(),
          name: data['name'] as String,
          balance: (data['current_balance'] as num?)?.toDouble() ?? 0.0,
          creditLimit: (data['credit_limit'] as num?)?.toDouble() ?? 0.0,
          phone: data['contact'] as String?,
          type: data['type'] as int? ?? 1, // 1=cash, 2=credit
        );
      }).toList();

      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError('فشل في تحميل العملاء: ${e.toString()}'));
    }
  }

  Future<Customer?> addCustomer({
    required String name,
    String? phone,
    String? address,
    int type = 1, // 1=cash, 2=credit
    double creditLimit = 0.0,
    double openingBalance = 0.0,
  }) async {
    try {
      final db = await _databaseService.database;

      // Start transaction
      Customer? newCustomer;
      await db.transaction((txn) async {
        // Find or create the "العملاء" parent account
        final customersParentAccount = await txn.query(
          'accounts',
          where: 'name = ? AND is_master = 1',
          whereArgs: ['العملاء'],
          limit: 1,
        );

        int customersParentId;
        int customersParentCId;

        if (customersParentAccount.isEmpty) {
          // Create العملاء parent account if it doesn't exist
          customersParentId = await txn.insert('accounts', {
            'c_id': 120,
            'code': '120',
            'name': 'العملاء',
            'is_master': 1,
            'type': 1, // Assets
            'national': 1,
            'is_active': 1,
            'allow_update_delete': 0,
            'balance': 0.0,
            'local_balance': 0.0,
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time':
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
          customersParentCId = 120;
        } else {
          customersParentId = customersParentAccount.first['id'] as int;
          customersParentCId = customersParentAccount.first['c_id'] as int;
        }

        // Generate unique code for the customer account
        final lastCustomerAccount = await txn.rawQuery(
          'SELECT MAX(CAST(code AS INTEGER)) as max_code FROM accounts WHERE master_id = ?',
          [customersParentId],
        );

        int nextCode = 12001;
        if (lastCustomerAccount.isNotEmpty &&
            lastCustomerAccount.first['max_code'] != null) {
          nextCode = (lastCustomerAccount.first['max_code'] as int) + 1;
        }

        // Create account for the customer
        final accountId = await txn.insert('accounts', {
          'c_id': nextCode,
          'code': nextCode.toString(),
          'name': name,
          'is_master': 0,
          'master_id': customersParentId,
          'master_c_id': customersParentCId,
          'type': 1, // Assets
          'national': 1,
          'statement': 'حساب العميل: $name',
          'is_active': 1,
          'allow_update_delete': 1,
          'balance': openingBalance,
          'local_balance': openingBalance,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time':
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        // Ensure classifications table has data
        final classificationsCount = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM classifications',
        );
        if ((classificationsCount.first['count'] as int) == 0) {
          await txn.insert('classifications', {
            'id': 1,
            'name': 'عملاء عاديين',
            'singler_name': 'عميل',
            'order': 1,
            'type': 1,
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time':
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
        }

        // Create the customer record
        final customerId = await txn.insert('customers', {
          'name': name,
          'type': type,
          'classification': 1,
          'classification_id': 1,
          'contact': phone,
          'contact_type': phone != null ? 1 : null,
          'is_active': 1,
          'account_id': accountId,
          'credit_limit': creditLimit,
          'current_balance': openingBalance,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time':
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        newCustomer = Customer(
          id: customerId.toString(),
          name: name,
          balance: openingBalance,
          creditLimit: creditLimit,
          phone: phone,
          type: type,
        );
      });

      // Reload customers list
      await loadCustomers();

      return newCustomer;
    } catch (e) {
      emit(CustomersError('فشل في إضافة العميل: ${e.toString()}'));
      return null;
    }
  }

  Future<void> updateCustomerBalance(
    String customerId,
    double newBalance,
  ) async {
    try {
      final db = await _databaseService.database;

      await db.transaction((txn) async {
        // Update customer balance
        await txn.update(
          'customers',
          {
            'current_balance': newBalance,
            'last_modification_time':
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [int.parse(customerId)],
        );

        // Fetch customer's account_id and update the related account balance
        final rows = await txn.query(
          'customers',
          columns: ['account_id'],
          where: 'id = ?',
          whereArgs: [int.parse(customerId)],
          limit: 1,
        );
        final accountId = rows.isNotEmpty
            ? rows.first['account_id'] as int?
            : null;
        if (accountId != null) {
          await txn.update(
            'accounts',
            {
              'balance': newBalance,
              'local_balance': newBalance,
              'last_modification_time':
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
            },
            where: 'id = ?',
            whereArgs: [accountId],
          );
        }
      });

      // Reload customers
      await loadCustomers();
    } catch (e) {
      emit(CustomersError('فشل في تحديث رصيد العميل: ${e.toString()}'));
    }
  }

  Future<void> loadSuppliers() async {
    try {
      emit(CustomersLoading());

      final db = await _databaseService.database;

      // Query suppliers (assuming type = 2 for suppliers)
      final suppliersData = await db.rawQuery('''
        SELECT 
          c.id,
          c.name,
          c.type,
          c.contact,
          c.is_active,
          c.credit_limit,
          c.current_balance,
          a.balance as account_balance
        FROM customers c
        LEFT JOIN accounts a ON c.account_id = a.id
        WHERE c.is_active = 1 AND c.type = 2
        ORDER BY c.name
      ''');

      final suppliers = suppliersData.map((data) {
        return Customer(
          id: data['id'].toString(),
          name: data['name'] as String,
          balance: (data['current_balance'] as num?)?.toDouble() ?? 0.0,
          creditLimit: (data['credit_limit'] as num?)?.toDouble() ?? 0.0,
          phone: data['contact'] as String?,
          type: data['type'] as int? ?? 2, // 2=supplier
        );
      }).toList();

      emit(SuppliersLoaded(suppliers));
    } catch (e) {
      emit(CustomersError('فشل في تحميل الموردين: ${e.toString()}'));
    }
  }
}
