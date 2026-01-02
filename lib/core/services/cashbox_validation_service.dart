import 'package:muhasib/core/services/database_service.dart';

/// Service to validate cashbox operations and prevent negative balance
class CashboxValidationService {
  final DatabaseService _databaseService;

  CashboxValidationService(this._databaseService);

  /// Check if a cashbox has sufficient balance for a withdrawal
  Future<CashboxBalanceCheckResult> checkSufficientBalance({
    required int cashboxId,
    required double amount,
  }) async {
    final db = await _databaseService.database;
    
    // Get the cashbox and its linked account
    final cashbox = await db.query(
      'funds',
      columns: ['id', 'name', 'account_id', 'is_active'],
      where: 'id = ?',
      whereArgs: [cashboxId],
      limit: 1,
    );

    if (cashbox.isEmpty) {
      return CashboxBalanceCheckResult(
        isValid: false,
        message: 'الصندوق غير موجود',
      );
    }

    final isActive = (cashbox.first['is_active'] as int?) == 1;
    if (!isActive) {
      return CashboxBalanceCheckResult(
        isValid: false,
        message: 'الصندوق غير نشط',
      );
    }

    final accountId = cashbox.first['account_id'] as int?;
    if (accountId == null) {
      return CashboxBalanceCheckResult(
        isValid: false,
        message: 'الصندوق غير مرتبط بحساب محاسبي',
      );
    }

    // Get the current balance from the linked account
    final account = await db.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (account.isEmpty) {
      return CashboxBalanceCheckResult(
        isValid: false,
        message: 'الحساب المرتبط غير موجود',
      );
    }

    final currentBalance = (account.first['balance'] as num?)?.toDouble() ?? 0.0;
    final cashboxName = cashbox.first['name'] as String;

    if (currentBalance < amount) {
      return CashboxBalanceCheckResult(
        isValid: false,
        currentBalance: currentBalance,
        message: 'الرصيد المتوفر في "$cashboxName" (${currentBalance.toStringAsFixed(2)}) أقل من المبلغ المطلوب (${amount.toStringAsFixed(2)})',
      );
    }

    return CashboxBalanceCheckResult(
      isValid: true,
      currentBalance: currentBalance,
      message: 'الرصيد كافي',
    );
  }

  /// Get the actual balance of a cashbox (from its linked account)
  Future<double> getCashboxBalance(int cashboxId) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT COALESCE(a.balance, 0.0) as balance
      FROM funds f
      LEFT JOIN accounts a ON a.id = f.account_id
      WHERE f.id = ?
    ''', [cashboxId]);

    if (result.isEmpty) return 0.0;
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Validate that a cashbox can be used for payment
  Future<CashboxValidationResult> validateCashboxForPayment({
    required int cashboxId,
    required int? currencyId,
  }) async {
    final db = await _databaseService.database;
    
    final cashbox = await db.query(
      'funds',
      columns: ['id', 'name', 'account_id', 'is_active', 'currency_id'],
      where: 'id = ?',
      whereArgs: [cashboxId],
      limit: 1,
    );

    if (cashbox.isEmpty) {
      return CashboxValidationResult(
        isValid: false,
        errors: ['الصندوق غير موجود'],
      );
    }

    final errors = <String>[];
    final cashboxData = cashbox.first;

    if ((cashboxData['is_active'] as int?) != 1) {
      errors.add('الصندوق غير نشط');
    }

    if (cashboxData['account_id'] == null) {
      errors.add('الصندوق غير مرتبط بحساب محاسبي - يرجى تعديل إعدادات الصندوق');
    }

    // Check currency match if specified
    if (currencyId != null && cashboxData['currency_id'] != null) {
      if (cashboxData['currency_id'] != currencyId) {
        errors.add('عملة الصندوق لا تتطابق مع عملة العملية');
      }
    }

    return CashboxValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      accountId: cashboxData['account_id'] as int?,
    );
  }

  /// Get all cashboxes with their actual balances
  Future<List<CashboxWithBalance>> getAllCashboxesWithBalances() async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        f.id,
        f.name,
        f.is_active,
        f.is_main_fund,
        f.account_id,
        f.currency_id,
        COALESCE(a.balance, 0.0) as actual_balance,
        c.code as currency_code
      FROM funds f
      LEFT JOIN accounts a ON a.id = f.account_id
      LEFT JOIN currencies c ON c.id = f.currency_id
      ORDER BY f.is_main_fund DESC, f.name ASC
    ''');

    return result.map((row) => CashboxWithBalance(
      id: row['id'] as int,
      name: row['name'] as String,
      isActive: (row['is_active'] as int?) == 1,
      isMainFund: (row['is_main_fund'] as int?) == 1,
      accountId: row['account_id'] as int?,
      currencyId: row['currency_id'] as int?,
      currencyCode: row['currency_code'] as String?,
      actualBalance: (row['actual_balance'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }
}

class CashboxBalanceCheckResult {
  final bool isValid;
  final double? currentBalance;
  final String message;

  CashboxBalanceCheckResult({
    required this.isValid,
    this.currentBalance,
    required this.message,
  });
}

class CashboxValidationResult {
  final bool isValid;
  final List<String> errors;
  final int? accountId;

  CashboxValidationResult({
    required this.isValid,
    required this.errors,
    this.accountId,
  });
}

class CashboxWithBalance {
  final int id;
  final String name;
  final bool isActive;
  final bool isMainFund;
  final int? accountId;
  final int? currencyId;
  final String? currencyCode;
  final double actualBalance;

  CashboxWithBalance({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isMainFund,
    this.accountId,
    this.currencyId,
    this.currencyCode,
    required this.actualBalance,
  });

  bool get hasLinkedAccount => accountId != null;
}
