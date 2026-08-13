import 'package:muhasib/core/services/account_config_service.dart';
import 'package:sqflite/sqflite.dart';

/// Service to validate accounting configuration at startup
/// خدمة للتحقق من صحة الإعدادات المحاسبية عند بدء التطبيق
class AccountingSetupValidator {
  final Database database;
  final AccountConfigService accountConfigService;

  AccountingSetupValidator({
    required this.database,
    required this.accountConfigService,
  });

  /// Validate that all default accounts exist in the database
  /// التحقق من وجود جميع الحسابات الافتراضية في قاعدة البيانات
  Future<AccountingValidationResult> validateDefaultAccounts() async {
    final errors = <String>[];
    final warnings = <String>[];

    // Get all configured account types
    final accountTypes = [
      (AccountConnectTypes.banks, 'البنوك'),
      (AccountConnectTypes.cashboxes, 'الصناديق'),
      (AccountConnectTypes.customers, 'العملاء'),
      (AccountConnectTypes.suppliers, 'الموردين'),
      (AccountConnectTypes.taxes, 'الضرائب'),
      (AccountConnectTypes.inventory, 'المخزون'),
      (AccountConnectTypes.sales, 'المبيعات'),
      (AccountConnectTypes.purchases, 'المشتريات'),
      (AccountConnectTypes.salesReturns, 'مردودات المبيعات'),
      (AccountConnectTypes.purchaseReturns, 'مردودات المشتريات'),
      (AccountConnectTypes.discountAllowed, 'الخصم المسموح به'),
      (AccountConnectTypes.discountEarned, 'الخصم المكتسب'),
      (AccountConnectTypes.costOfGoodsSold, 'تكلفة البضاعة المباعة'),
    ];

    for (final (type, name) in accountTypes) {
      try {
        final accountCId = await accountConfigService.getAccountId(type);

        // Check if account exists
        final result = await database.query(
          'accounts',
          columns: ['id', 'c_id', 'name', 'is_active'],
          where: 'c_id = ?',
          whereArgs: [accountCId],
          limit: 1,
        );

        if (result.isEmpty) {
          errors.add(
            'الحساب الافتراضي لـ "$name" (c_id: $accountCId) غير موجود',
          );
        } else {
          final account = result.first;
          final isActive = (account['is_active'] as int?) == 1;
          if (!isActive) {
            warnings.add('الحساب الافتراضي لـ "$name" غير نشط');
          }
        }
      } catch (e) {
        errors.add('خطأ في التحقق من حساب "$name": ${e.toString()}');
      }
    }

    return AccountingValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate that account_connects table has all required entries
  /// التحقق من وجود جميع الربطات المطلوبة
  Future<AccountingValidationResult> validateAccountConnects() async {
    final errors = <String>[];
    final warnings = <String>[];

    final requiredTypes = [
      (AccountConnectTypes.cashboxes, 'الصناديق', true),
      (AccountConnectTypes.customers, 'العملاء', true),
      (AccountConnectTypes.suppliers, 'الموردين', true),
      (AccountConnectTypes.sales, 'المبيعات', true),
      (AccountConnectTypes.purchases, 'المشتريات', true),
      (AccountConnectTypes.inventory, 'المخزون', false),
      (AccountConnectTypes.taxes, 'الضرائب', false),
    ];

    for (final (type, name, isRequired) in requiredTypes) {
      final result = await database.query(
        'account_connects',
        where: 'account_connect_type = ?',
        whereArgs: [type],
        limit: 1,
      );

      if (result.isEmpty || result.first['c_id'] == null) {
        if (isRequired) {
          warnings.add(
            'لم يتم تهيئة ربط الحساب لـ "$name" (سيتم استخدام القيمة الافتراضية)',
          );
        }
      }
    }

    return AccountingValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Run all validations
  /// تشغيل جميع عمليات التحقق
  Future<AccountingValidationResult> validateAll() async {
    final accounts = await validateDefaultAccounts();
    final connects = await validateAccountConnects();

    return AccountingValidationResult(
      isValid: accounts.isValid && connects.isValid,
      errors: [...accounts.errors, ...connects.errors],
      warnings: [...accounts.warnings, ...connects.warnings],
    );
  }

  /// Create missing default accounts
  /// إنشاء الحسابات الافتراضية المفقودة
  Future<void> createMissingDefaultAccounts() async {
    final defaultAccounts = [
      {
        'c_id': DefaultAccountIds.sales,
        'code': '4110',
        'name': 'إيرادات المبيعات',
        'type': 4,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.cash,
        'code': '1110',
        'name': 'الصندوق',
        'type': 0,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.bank,
        'code': '1120',
        'name': 'البنك',
        'type': 0,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.customers,
        'code': '1130',
        'name': 'العملاء',
        'type': 0,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.suppliers,
        'code': '2110',
        'name': 'الموردين',
        'type': 1,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.tax,
        'code': '2140',
        'name': 'ضريبة القيمة المضافة',
        'type': 1,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.inventory,
        'code': '1140',
        'name': 'المخزون',
        'type': 0,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.purchases,
        'code': '5110',
        'name': 'المشتريات',
        'type': 3,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.salesReturns,
        'code': '4150',
        'name': 'مردودات المبيعات',
        'type': 4,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.purchaseReturns,
        'code': '5150',
        'name': 'مردودات المشتريات',
        'type': 3,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.discountAllowed,
        'code': '5120',
        'name': 'خصم مسموح به',
        'type': 3,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.discountEarned,
        'code': '4140',
        'name': 'خصم مكتسب',
        'type': 4,
        'master_id': null,
      },
      {
        'c_id': DefaultAccountIds.costOfGoodsSold,
        'code': '5100',
        'name': 'تكلفة البضاعة المباعة',
        'type': 3,
        'master_id': null,
      },
    ];

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final account in defaultAccounts) {
      final existing = await database.query(
        'accounts',
        where: 'c_id = ?',
        whereArgs: [account['c_id']],
        limit: 1,
      );

      if (existing.isEmpty) {
        await database.insert('accounts', {
          ...account,
          'is_master': 0,
          'national': 1,
          'is_active': 1,
          'allow_update_delete': 0, // Protect default accounts
          'balance': 0.0,
          'local_balance': 0.0,
          'creation_time': now,
          'last_modification_time': now,
        });
      }
    }
  }
}

/// Result of accounting validation
class AccountingValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const AccountingValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    if (errors.isNotEmpty) {
      buffer.writeln('أخطاء:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    if (warnings.isNotEmpty) {
      buffer.writeln('تحذيرات:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    return buffer.toString();
  }
}
