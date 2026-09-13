import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/currencies/data/models/currency_exchange_model.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_exchange_entity.dart';
import 'package:sqflite/sqflite.dart';

/// Service for handling currency exchange operations with full accounting integration
class CurrencyExchangeService {
  final DatabaseService _databaseService;

  CurrencyExchangeService(this._databaseService);

  /// Get the next exchange number
  Future<int> getNextExchangeNumber() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(number), 0) + 1 as next_number FROM currency_exchanges',
    );
    return (result.first['next_number'] as int?) ?? 1;
  }

  /// Create a currency exchange transaction with automatic journal entry
  Future<Either<Failure, CurrencyExchangeEntity>> createExchange({
    required int creditAccountId,
    required int creditCurrencyId,
    required String creditCurrencyCode,
    required double creditAmount,
    required double creditExchangeRate,
    required int debitAccountId,
    required int debitCurrencyId,
    required String debitCurrencyCode,
    required double debitAmount,
    required double debitExchangeRate,
    required DateTime date,
    String? notes,
    double? customExchangeRate,
    int? exchangeDifferenceAccountId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      // Calculate local amounts
      final creditLocalAmount = creditAmount * creditExchangeRate;
      final debitLocalAmount = debitAmount * debitExchangeRate;
      
      // Calculate exchange rate difference:
      // If debitLocalAmount > creditLocalAmount => Profit (Gain from exchange)
      // If debitLocalAmount < creditLocalAmount => Loss (Expense from exchange)
      final exchangeDifference = debitLocalAmount - creditLocalAmount;
      // FIX: use 0.01 threshold consistent with other validations, but handle dust >0.001
      final isProfit = exchangeDifference > 0.01;
      final isLoss = exchangeDifference < -0.01;
      final diffAbs = exchangeDifference.abs();
      
      // Start transaction - FIX HIGH-31: generate number INSIDE txn to avoid race
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        // Generate exchange number inside transaction
        final numResult = await txn.rawQuery('SELECT COALESCE(MAX(number), 0) + 1 as next_number FROM currency_exchanges');
        final exchangeNumber = (numResult.first['next_number'] as int?) ?? 1;
        
        // 1. Create the exchange record
        final exchangeData = {
          'number': exchangeNumber,
          'date': date.millisecondsSinceEpoch ~/ 1000,
          'statement': 'صرف عملات - تحويل من $creditCurrencyCode إلى $debitCurrencyCode',
          'credit_account_id': creditAccountId,
          'credit_currency_id': creditCurrencyId,
          'credit_currency_code': creditCurrencyCode,
          'credit_amount': creditAmount,
          'credit_exchange_rate': creditExchangeRate,
          'credit_local_amount': creditLocalAmount,
          'debit_account_id': debitAccountId,
          'debit_currency_id': debitCurrencyId,
          'debit_currency_code': debitCurrencyCode,
          'debit_amount': debitAmount,
          'debit_exchange_rate': debitExchangeRate,
          'debit_local_amount': debitLocalAmount,
          'exchange_rate_difference': exchangeDifference,
          'exchange_difference_account_id': exchangeDifferenceAccountId,
          'creator_id': 1,
          'last_modifier_id': 1,
          'creation_time': now,
          'last_modification_time': now,
          'status': 1, // Posted immediately
        };
        
        final exchangeId = await txn.insert('currency_exchanges', exchangeData);
        
        // 2. Resolve the exchange difference account BEFORE writing anything.
        //    If a significant difference exists without a target account, the
        //    entry would be unbalanced - so abort instead of corrupting the ledger.
        final bool hasSignificantDiff = diffAbs > 0.01;
        final int? diffAccountId = hasSignificantDiff
            ? (exchangeDifferenceAccountId ??
                  await _resolveExchangeDifferenceAccount(txn, isProfit))
            : exchangeDifferenceAccountId;
        if (hasSignificantDiff && diffAccountId == null) {
          throw Exception(
            'لا يمكن ترحيل قيد صرف العملات: فرق الصرف ${diffAbs.toStringAsFixed(2)} '
            'ولا يوجد حساب لأرباح/خسائر فروق الصرف',
          );
        }

        // Actual totals including the difference line
        final totalDebit =
            debitLocalAmount + (hasSignificantDiff && isLoss ? diffAbs : 0.0);
        final totalCredit =
            creditLocalAmount + (hasSignificantDiff && isProfit ? diffAbs : 0.0);
        if ((totalDebit - totalCredit).abs() > 0.01) {
          throw Exception(
            'قيد صرف العملات غير متوازن (مدين: ${totalDebit.toStringAsFixed(2)}، '
            'دائن: ${totalCredit.toStringAsFixed(2)})',
          );
        }

        // 3. Create journal entry for the exchange
        final journalNumber = 'EX-$exchangeNumber';
        final journalDescription = 'قيد صرف عملات رقم $exchangeNumber - تحويل من $creditCurrencyCode إلى $debitCurrencyCode';
        final journalEntryData = {
          'number': journalNumber,
          'entry_date': date.millisecondsSinceEpoch ~/ 1000,
          'description': journalDescription,
          'reference_number': 'EX-$exchangeNumber',
          'reference_type': 'currency_exchange',
          'reference_id': exchangeId,
          'notes': notes,
          'status': 1,
          'is_posted': 1,
          'total_debit': totalDebit,
          'total_credit': totalCredit,
          'difference': _round2(totalDebit - totalCredit),
          'creator_id': 1,
          'last_modifier_id': 1,
          'creation_time': now,
          'last_modification_time': now,
        };
        
        final journalEntryId = await txn.insert('journal_entries', journalEntryData);
        
        // 3. Create journal entry lines
        int lineNumber = 1;
        
        // Debit line: the currency being acquired (increase asset)
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalEntryId,
          'line_number': lineNumber++,
          'account_id': debitAccountId,
          'account_code': '', // Will be fetched if needed
          'account_name': '', // Will be fetched if needed
          'currency_id': debitCurrencyId,
          'currency_code': debitCurrencyCode,
          'debit_amount': debitLocalAmount,
          'credit_amount': 0.0,
          'notes': 'شراء $debitAmount $debitCurrencyCode',
        });
        
        // Credit line: the currency being sold (decrease asset)
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalEntryId,
          'line_number': lineNumber++,
          'account_id': creditAccountId,
          'account_code': '',
          'account_name': '',
          'currency_id': creditCurrencyId,
          'currency_code': creditCurrencyCode,
          'debit_amount': 0.0,
          'credit_amount': creditLocalAmount,
          'notes': 'بيع $creditAmount $creditCurrencyCode',
        });
        
        // 4. If there's an exchange difference, record it (threshold 0.01)
        if (hasSignificantDiff && diffAccountId != null) {
          if (isProfit) {
            // Profit from exchange - Credit to income
            await txn.insert('journal_entry_lines', {
              'journal_entry_id': journalEntryId,
              'line_number': lineNumber++,
              'account_id': diffAccountId,
              'account_code': '',
              'account_name': '',
              'currency_id': null,
              'currency_code': '',
              'debit_amount': 0.0,
              'credit_amount': diffAbs,
              'notes': 'أرباح فروق صرف عملات',
            });
          } else {
            // Loss from exchange - Debit to expense
            await txn.insert('journal_entry_lines', {
              'journal_entry_id': journalEntryId,
              'line_number': lineNumber++,
              'account_id': diffAccountId,
              'account_code': '',
              'account_name': '',
              'currency_id': null,
              'currency_code': '',
              'debit_amount': diffAbs,
              'credit_amount': 0.0,
              'notes': 'خسائر فروق صرف عملات',
            });
          }
        }
        
        // 5. Update the exchange record with journal entry ID
        await txn.update(
          'currency_exchanges',
          {
            'journal_entry_id': journalEntryId,
            if (diffAccountId != null && exchangeDifferenceAccountId == null)
              'exchange_difference_account_id': diffAccountId,
          },
          where: 'id = ?',
          whereArgs: [exchangeId],
        );

        // 6. Apply balance updates to accounts
        await _applyAccountBalanceDelta(txn, debitAccountId, debitLocalAmount);
        await _applyAccountBalanceDelta(txn, creditAccountId, -creditLocalAmount);
        if (hasSignificantDiff && diffAccountId != null) {
          if (isProfit) {
            await _applyAccountBalanceDelta(txn, diffAccountId, -diffAbs);
          } else {
            await _applyAccountBalanceDelta(txn, diffAccountId, diffAbs);
          }
        }
        
        // 6. Record exchange rate history
        await _recordExchangeRateHistory(
          txn,
          creditCurrencyId,
          creditExchangeRate,
          date,
        );
        await _recordExchangeRateHistory(
          txn,
          debitCurrencyId,
          debitExchangeRate,
          date,
        );
        
        // Return the created exchange entity
        final createdExchange = CurrencyExchangeEntity(
          id: exchangeId,
          number: exchangeNumber,
          date: date,
          statement: exchangeData['statement'] as String,
          creditAccountId: creditAccountId,
          creditCurrencyId: creditCurrencyId,
          creditCurrencyCode: creditCurrencyCode,
          creditAmount: creditAmount,
          creditExchangeRate: creditExchangeRate,
          creditLocalAmount: creditLocalAmount,
          debitAccountId: debitAccountId,
          debitCurrencyId: debitCurrencyId,
          debitCurrencyCode: debitCurrencyCode,
          debitAmount: debitAmount,
          debitExchangeRate: debitExchangeRate,
          debitLocalAmount: debitLocalAmount,
          exchangeRateDifference: exchangeDifference,
          exchangeDifferenceAccountId: exchangeDifferenceAccountId,
          journalEntryId: journalEntryId,
          creatorId: 1,
          lastModifierId: 1,
          creationTime: now,
          lastModificationTime: now,
          notes: notes,
          status: 1,
        );
        
        return Right(createdExchange);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء عملية صرف العملات: ${e.toString()}'));
    }
  }

  /// Record exchange rate history for tracking
  Future<void> _recordExchangeRateHistory(
    Transaction txn,
    int currencyId,
    double exchangeRate,
    DateTime effectiveDate,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // FIX LOW-34: end_date exclusive to avoid overlap same day
    await txn.update(
      'currency_exchange_rates',
      {
        'end_date': effectiveDate.millisecondsSinceEpoch ~/ 1000 - 1,
        'is_active': 0,
        'last_modification_time': now,
      },
      where: 'currency_id = ? AND is_active = 1',
      whereArgs: [currencyId],
    );
    
    // Insert new rate
    await txn.insert('currency_exchange_rates', {
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'effective_date': effectiveDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': null,
      'notes': 'سعر صرف مسجل تلقائياً من عملية صرف',
      'is_active': 1,
      'creation_time': now,
      'last_modification_time': now,
    });
  }

  /// Get all currency exchange transactions
  Future<Either<Failure, List<CurrencyExchangeEntity>>> getAllExchanges() async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'currency_exchanges',
        orderBy: 'date DESC, id DESC',
      );
      
      final exchanges = results
          .map((e) => CurrencyExchangeModel.fromJson(e).toEntity())
          .toList();
      
      return Right(exchanges);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب عمليات صرف العملات: ${e.toString()}'));
    }
  }

  /// Get exchange by ID
  Future<Either<Failure, CurrencyExchangeEntity>> getExchangeById(int id) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'currency_exchanges',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (results.isEmpty) {
        return Left(ValidationFailure(message: 'عملية الصرف غير موجودة'));
      }
      
      final exchange = CurrencyExchangeModel.fromJson(results.first).toEntity();
      return Right(exchange);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب عملية الصرف: ${e.toString()}'));
    }
  }

  /// Get exchange rate history for a currency
  Future<Either<Failure, List<ExchangeRateHistoryModel>>> getExchangeRateHistory(
    int currencyId,
  ) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'currency_exchange_rates',
        where: 'currency_id = ?',
        whereArgs: [currencyId],
        orderBy: 'effective_date DESC',
      );
      
      final history = results
          .map((e) => ExchangeRateHistoryModel.fromJson(e))
          .toList();
      
      return Right(history);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب تاريخ أسعار الصرف: ${e.toString()}'));
    }
  }

  /// Get the exchange rate for a currency at a specific date
  Future<double?> getExchangeRateAtDate(int currencyId, DateTime date) async {
    try {
      final db = await _databaseService.database;
      final dateTimestamp = date.millisecondsSinceEpoch ~/ 1000;
      
      final results = await db.rawQuery('''
        SELECT exchange_rate FROM currency_exchange_rates
        WHERE currency_id = ? 
          AND effective_date <= ?
          AND (end_date IS NULL OR end_date >= ?)
        ORDER BY effective_date DESC
        LIMIT 1
      ''', [currencyId, dateTimestamp, dateTimestamp]);
      
      if (results.isNotEmpty) {
        return (results.first['exchange_rate'] as num?)?.toDouble();
      }
      
      // Fallback to current currency rate
      final currencyResult = await db.query(
        'currencies',
        columns: ['exchange_rate'],
        where: 'id = ?',
        whereArgs: [currencyId],
      );
      
      if (currencyResult.isNotEmpty) {
        return (currencyResult.first['exchange_rate'] as num?)?.toDouble();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate exchange rate difference for revaluation
  Future<Either<Failure, double>> calculateRevaluationDifference({
    required int accountId,
    required int currencyId,
    required double currentRate,
    required DateTime asOfDate,
  }) async {
    try {
      final db = await _databaseService.database;
      
      // Get account balance in original currency
      final balanceResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
        FROM journal_entry_lines jel
        INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE jel.account_id = ? 
          AND jel.currency_id = ?
          AND je.is_posted = 1
          AND je.entry_date <= ?
      ''', [accountId, currencyId, asOfDate.millisecondsSinceEpoch ~/ 1000]);
      
      final balance = (balanceResult.first['balance'] as num?)?.toDouble() ?? 0.0;
      
      // Get the original local balance - FIX MEDIUM-33: use historic rate, not current currencies.exchange_rate
      final localBalanceResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(
            (jel.debit_amount * COALESCE(
              (SELECT exchange_rate FROM currency_exchange_rates 
               WHERE currency_id = jel.currency_id 
                 AND effective_date <= je.entry_date 
                 AND (end_date IS NULL OR end_date >= je.entry_date) 
               ORDER BY effective_date DESC LIMIT 1), 1)) - 
            (jel.credit_amount * COALESCE(
              (SELECT exchange_rate FROM currency_exchange_rates 
               WHERE currency_id = jel.currency_id 
                 AND effective_date <= je.entry_date 
                 AND (end_date IS NULL OR end_date >= je.entry_date) 
               ORDER BY effective_date DESC LIMIT 1), 1))
          ), 0) as local_balance
        FROM journal_entry_lines jel
        INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE jel.account_id = ? 
          AND jel.currency_id = ?
          AND je.is_posted = 1
          AND je.entry_date <= ?
      ''', [accountId, currencyId, asOfDate.millisecondsSinceEpoch ~/ 1000]);
      
      final originalLocalBalance = (localBalanceResult.first['local_balance'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate new local value at current rate
      final newLocalBalance = balance * currentRate;
      
      // Difference is the revaluation amount
      final difference = newLocalBalance - originalLocalBalance;
      
      return Right(difference);
    } catch (e) {
      return Left(UnknownFailure('فشل في حساب فروق إعادة التقييم: ${e.toString()}'));
    }
  }

  /// Create revaluation journal entry for exchange rate changes
  Future<Either<Failure, int>> createRevaluationEntry({
    required int accountId,
    required int currencyId,
    required double newExchangeRate,
    required double revaluationAmount,
    required int gainLossAccountId,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Get next journal entry number
        final numberResult = await txn.rawQuery(
          "SELECT COALESCE(MAX(CAST(REPLACE(number, 'RV-', '') AS INTEGER)), 0) + 1 as next FROM journal_entries WHERE number LIKE 'RV-%'"
        );
        final nextNumber = (numberResult.first['next'] as int?) ?? 1;
        
        // Create journal entry for revaluation
        final journalData = {
          'number': 'RV-$nextNumber',
          'entry_date': date.millisecondsSinceEpoch ~/ 1000,
          'description': 'قيد تسوية فروق أسعار صرف العملات',
          'reference_number': 'RV-$nextNumber',
          'reference_type': 'revaluation',
          'notes': notes ?? 'إعادة تقييم أرصدة العملات الأجنبية',
          'status': 1,
          'is_posted': 1,
          'total_debit': revaluationAmount.abs(),
          'total_credit': revaluationAmount.abs(),
          'difference': 0.0,
          'creator_id': 1,
          'last_modifier_id': 1,
          'creation_time': now,
          'last_modification_time': now,
        };
        
        final journalId = await txn.insert('journal_entries', journalData);
        
        if (revaluationAmount > 0) {
          // Gain: Debit asset account, Credit gain account
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': journalId,
            'line_number': 1,
            'account_id': accountId,
            'currency_id': currencyId,
            'debit_amount': revaluationAmount,
            'credit_amount': 0.0,
            'notes': 'زيادة قيمة الأصول بسبب ارتفاع سعر الصرف',
          });
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': journalId,
            'line_number': 2,
            'account_id': gainLossAccountId,
            'debit_amount': 0.0,
            'credit_amount': revaluationAmount,
            'notes': 'أرباح فروق أسعار صرف العملات',
          });
        } else {
          // Loss: Debit loss account, Credit asset account
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': journalId,
            'line_number': 1,
            'account_id': gainLossAccountId,
            'debit_amount': -revaluationAmount,
            'credit_amount': 0.0,
            'notes': 'خسائر فروق أسعار صرف العملات',
          });
          await txn.insert('journal_entry_lines', {
            'journal_entry_id': journalId,
            'line_number': 2,
            'account_id': accountId,
            'currency_id': currencyId,
            'debit_amount': 0.0,
            'credit_amount': -revaluationAmount,
            'notes': 'انخفاض قيمة الأصول بسبب هبوط سعر الصرف',
          });
        }
        
        // Apply balance updates to accounts
        if (revaluationAmount > 0) {
          await _applyAccountBalanceDelta(txn, accountId, revaluationAmount);
          await _applyAccountBalanceDelta(txn, gainLossAccountId, -revaluationAmount);
        } else {
          final loss = -revaluationAmount;
          await _applyAccountBalanceDelta(txn, gainLossAccountId, loss);
          await _applyAccountBalanceDelta(txn, accountId, -loss);
        }

        // Record the new exchange rate in history
        await _recordExchangeRateHistory(txn, currencyId, newExchangeRate, date);
        
        return Right(journalId);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء قيد إعادة التقييم: ${e.toString()}'));
    }
  }

  Future<void> _applyAccountBalanceDelta(
    Transaction txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['balance', 'local_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final currentLocal = (rows.first['local_balance'] as num?)?.toDouble() ?? current;
    final newBalance = current + delta;
    final newLocal = currentLocal + delta;
    await txn.update(
      'accounts',
      {
        'balance': newBalance,
        'local_balance': newLocal,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int?> _resolveExchangeDifferenceAccount(Transaction txn, bool isProfit) async {
    // 1. Try account_connects (type 16)
    final connect = await txn.query(
      'account_connects',
      columns: ['c_id'],
      where: 'account_connect_type = ?',
      whereArgs: [16],
      limit: 1,
    );
    final targetCId = connect.isNotEmpty
        ? (connect.first['c_id'] as int?)
        : (isProfit ? 4160 : 3170);

    if (targetCId != null) {
      final acc = await txn.query(
        'accounts',
        columns: ['id'],
        where: 'c_id = ?',
        whereArgs: [targetCId],
        limit: 1,
      );
      if (acc.isNotEmpty && acc.first['id'] != null) {
        return acc.first['id'] as int;
      }
    }

    // 2. Fallback by name search
    final nameSearch = isProfit ? '%أرباح فروق صرف%' : '%خسائر فروق صرف%';
    final byName = await txn.query(
      'accounts',
      columns: ['id'],
      where: 'name LIKE ?',
      whereArgs: [nameSearch],
      limit: 1,
    );
    if (byName.isNotEmpty && byName.first['id'] != null) {
      return byName.first['id'] as int;
    }

    // 3. Auto-create the account (same pattern as sales/purchases services)
    //    so a significant exchange difference can never remain unposted.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      return await txn.insert('accounts', {
        'c_id': isProfit ? 4160 : 3170,
        'code': isProfit ? '4005' : '3006',
        'name': isProfit ? 'أرباح فروق صرف العملات' : 'خسائر فروق صرف العملات',
        'is_master': 0,
        'master_id': null,
        'master_c_id': isProfit ? 4000 : 3000,
        'type': isProfit ? 3 : 4,
        'national': 1,
        'statement': 'قائمة الدخل',
        'is_active': 1,
        'allow_update_delete': 1,
        'balance': 0.0,
        'local_balance': 0.0,
        'creation_time': now,
        'last_modification_time': now,
      });
    } catch (_) {
      // Unique constraint (c_id/code) race: re-query by c_id
      final retry = await txn.query(
        'accounts',
        columns: ['id'],
        where: 'c_id = ? OR code = ?',
        whereArgs: [isProfit ? 4160 : 3170, isProfit ? '4005' : '3006'],
        limit: 1,
      );
      return retry.isNotEmpty ? retry.first['id'] as int : null;
    }
  }

  double _round2(double value) => (value * 100).roundToDouble() / 100;
}
