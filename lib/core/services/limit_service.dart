import 'package:muhasib/core/services/database_service.dart';

class LimitService {
  static final LimitService _instance = LimitService._internal();
  factory LimitService() => _instance;
  LimitService._internal();

  /// فحص سقف الحساب قبل تسجيل العملية
  /// [accountId]: معرف الحساب
  /// [amount]: المبلغ الجديد المراد تسجيله
  /// [isDebit]: هل الحركة مدينة أم دائنة؟
  Future<LimitCheckResult> checkLimit({
    required int accountId,
    required double amount,
    required bool isDebit,
  }) async {
    final db = await DatabaseService().database;

    // 1. البحث عن سقف مفعل لهذا الحساب
    final limitMaps = await db.query(
      'account_limits',
      where: 'account_id = ? AND is_active = 1',
      whereArgs: [accountId],
      limit: 1,
    );

    if (limitMaps.isEmpty) {
      return LimitCheckResult.allowed(); // لا يوجد سقف محدد لهذا الحساب
    }

    final limit = limitMaps.first;
    final debitLimit = (limit['debit_limit'] as num).toDouble();
    final creditLimit = (limit['credit_limit'] as num).toDouble();

    // 2. جلب الرصيد الحالي للحساب (من جدول الحسابات)
    final accountMaps = await db.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (accountMaps.isEmpty) return LimitCheckResult.allowed();

    double currentBalance = (accountMaps.first['balance'] as num).toDouble();

    // حساب الرصيد المتوقع بعد العملية
    // في المحاسبة: المدين يزيد الرصيد المدين، والدائن يقلله (أو يزيد الرصيد الدائن)
    // هنا نفترض أن الفحص يتم بناءً على إجمالي الحركات المدينة أو الدائنة المسموح بها كـ "سقف"

    if (isDebit && debitLimit > 0) {
      if (currentBalance + amount > debitLimit) {
        return LimitCheckResult.blocked(
          message:
              'تجاوز سقف المدين المسموح به لهذا الحساب! (السقف: $debitLimit)',
          currentAmount: currentBalance,
          limitAmount: debitLimit,
        );
      }
    } else if (!isDebit && creditLimit > 0) {
      // بالنسبة للدائن، غالباً ما نقارن القيمة المطلقة أو إجمالي الحركات الدائنة
      if (currentBalance.abs() + amount > creditLimit) {
        return LimitCheckResult.blocked(
          message:
              'تجاوز سقف الدائن المسموح به لهذا الحساب! (السقف: $creditLimit)',
          currentAmount: currentBalance.abs(),
          limitAmount: creditLimit,
        );
      }
    }

    return LimitCheckResult.allowed();
  }
}

class LimitCheckResult {
  final bool isAllowed;
  final String? message;
  final double currentAmount;
  final double limitAmount;

  LimitCheckResult({
    required this.isAllowed,
    this.message,
    this.currentAmount = 0,
    this.limitAmount = 0,
  });

  factory LimitCheckResult.allowed() => LimitCheckResult(isAllowed: true);
  factory LimitCheckResult.blocked({
    required String message,
    required double currentAmount,
    required double limitAmount,
  }) => LimitCheckResult(
    isAllowed: false,
    message: message,
    currentAmount: currentAmount,
    limitAmount: limitAmount,
  );
}
