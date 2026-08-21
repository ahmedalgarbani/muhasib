import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Account Validation Service
/// خدمة التحقق من صحة الحسابات وقيود الحذف
class AccountValidationService {
  final Database _database;
  final JournalRepository? _journalRepository;

  AccountValidationService({
    required Database database,
    JournalRepository? journalRepository,
  })  : _database = database,
        _journalRepository = journalRepository;

  /// Check if an account is used in any journal entry lines
  /// التحقق من استخدام الحساب في قيود محاسبية
  Future<bool> isAccountUsedInJournalEntries(int accountId) async {
    final result = await _database.rawQuery('''
      SELECT COUNT(*) as count 
      FROM journal_entry_lines 
      WHERE account_id = ?
    ''', [accountId]);

    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// Get the count of journal entries using an account
  /// الحصول على عدد القيود التي تستخدم الحساب
  Future<int> getJournalEntryCountForAccount(int accountId) async {
    final result = await _database.rawQuery('''
      SELECT COUNT(DISTINCT journal_entry_id) as count 
      FROM journal_entry_lines 
      WHERE account_id = ?
    ''', [accountId]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if an account has non-zero balance
  /// التحقق من وجود رصيد غير صفري للحساب
  Future<bool> hasNonZeroBalance(int accountId) async {
    final result = await _database.query(
      'accounts',
      columns: ['balance', 'local_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final balance = (result.first['balance'] as num?)?.toDouble() ?? 0;
    final localBalance = (result.first['local_balance'] as num?)?.toDouble() ?? 0;

    // Allow for small floating-point differences
    return balance.abs() > 0.01 || localBalance.abs() > 0.01;
  }

  /// Check if an account has child accounts
  /// التحقق من وجود حسابات فرعية
  Future<bool> hasChildAccounts(int accountId) async {
    final result = await _database.rawQuery('''
      SELECT COUNT(*) as count 
      FROM accounts 
      WHERE master_id = ?
    ''', [accountId]);

    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// Validate if an account can be deleted
  /// التحقق من إمكانية حذف الحساب
  Future<Either<Failure, bool>> canDeleteAccount(int accountId) async {
    try {
      // Check if account exists
      final accountResult = await _database.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );

      if (accountResult.isEmpty) {
        return Left(NotFoundFailure('الحساب غير موجود'));
      }

      final account = accountResult.first;
      final allowUpdateDelete = (account['allow_update_delete'] as int?) == 1;

      if (!allowUpdateDelete) {
        return Left(ValidationFailure(message:'هذا الحساب محمي ولا يمكن حذفه'));
      }

      // Check for child accounts
      if (await hasChildAccounts(accountId)) {
        return Left(ValidationFailure(message:'لا يمكن حذف الحساب لوجود حسابات فرعية مرتبطة به'));
      }

      // Check for journal entries
      if (await isAccountUsedInJournalEntries(accountId)) {
        final count = await getJournalEntryCountForAccount(accountId);
        return Left(ValidationFailure(message:
          'لا يمكن حذف الحساب لوجود $count قيد/قيود محاسبية مرتبطة به',
        ));
      }

      // Check for non-zero balance
      if (await hasNonZeroBalance(accountId)) {
        return Left(ValidationFailure(message:'لا يمكن حذف الحساب لوجود رصيد غير صفري'));
      }

      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure('خطأ في التحقق من إمكانية الحذف: ${e.toString()}'));
    }
  }

  /// Check if a sub-account's type matches its parent's type
  /// التحقق من تطابق نوع الحساب الفرعي مع نوع الحساب الرئيسي
  Future<Either<Failure, bool>> validateAccountTypeHierarchy({
    required int? parentId,
    required int accountType,
  }) async {
    if (parentId == null) {
      // Master account, no need to validate
      return const Right(true);
    }

    try {
      final parentResult = await _database.query(
        'accounts',
        columns: ['type'],
        where: 'id = ?',
        whereArgs: [parentId],
        limit: 1,
      );

      if (parentResult.isEmpty) {
        return Left(NotFoundFailure('الحساب الرئيسي غير موجود'));
      }

      final parentType = parentResult.first['type'] as int;

      if (parentType != accountType) {
        return Left(ValidationFailure(message:
          'نوع الحساب الفرعي يجب أن يكون من نفس نوع الحساب الرئيسي',
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure('خطأ في التحقق من التسلسل الهرمي: ${e.toString()}'));
    }
  }

  /// Validate a journal entry is balanced
  /// التحقق من توازن القيد المحاسبي - FIX MEDIUM-39: negative/zero checks
  Either<Failure, bool> validateJournalEntryBalance(JournalEntryEntity entry) {
    final totalDebit = entry.lines.fold<double>(0, (sum, line) => sum + line.debit);
    final totalCredit = entry.lines.fold<double>(0, (sum, line) => sum + line.credit);

    if (totalDebit <= 0.01 && totalCredit <= 0.01) {
      return Left(ValidationFailure(message: 'مبلغ القيد يجب أن يكون أكبر من صفر'));
    }
    // Allow for small floating-point differences
    if ((totalDebit - totalCredit).abs() > 0.01) {
      return Left(ValidationFailure(message:
        'القيد غير متوازن: المدين ($totalDebit) لا يساوي الدائن ($totalCredit)',
      ));
    }

    if (entry.lines.isEmpty) {
      return Left(ValidationFailure(message:'القيد يجب أن يحتوي على سطر واحد على الأقل'));
    }

    // Check that each line has either debit OR credit, not both, and no negatives
    for (final line in entry.lines) {
      if (line.debit < -0.01 || line.credit < -0.01) {
        return Left(ValidationFailure(message: 'السطر رقم ${line.lineNumber}: المبلغ لا يمكن أن يكون سالباً'));
      }
      if (line.debit > 0 && line.credit > 0) {
        return Left(ValidationFailure(message:
          'السطر رقم ${line.lineNumber}: لا يمكن أن يحتوي على مدين ودائن في نفس الوقت',
        ));
      }
      if (line.debit == 0 && line.credit == 0) {
        return Left(ValidationFailure(message:
          'السطر رقم ${line.lineNumber}: يجب تحديد مبلغ مدين أو دائن',
        ));
      }
    }

    return const Right(true);
  }

  /// Validate that all accounts in a journal entry exist
  /// التحقق من وجود جميع الحسابات في القيد
  Future<Either<Failure, bool>> validateJournalEntryAccounts(
    JournalEntryEntity entry,
  ) async {
    for (final line in entry.lines) {
      if (line.accountId == null) {
        return Left(ValidationFailure(message:
          'السطر رقم ${line.lineNumber}: يجب تحديد الحساب',
        ));
      }

      final accountResult = await _database.query(
        'accounts',
        columns: ['id', 'is_active', 'is_master'],
        where: 'id = ?',
        whereArgs: [line.accountId],
        limit: 1,
      );

      if (accountResult.isEmpty) {
        return Left(NotFoundFailure(
          'السطر رقم ${line.lineNumber}: الحساب غير موجود',
        ));
      }

      final account = accountResult.first;
      final isActive = (account['is_active'] as int?) == 1;
      final isMaster = (account['is_master'] as int?) == 1;

      if (!isActive) {
        return Left(ValidationFailure(message:
          'السطر رقم ${line.lineNumber}: الحساب غير نشط',
        ));
      }

      if (isMaster) {
        return Left(ValidationFailure(message:
          'السطر رقم ${line.lineNumber}: لا يمكن الترحيل إلى حساب رئيسي',
        ));
      }
    }

    return const Right(true);
  }
}


