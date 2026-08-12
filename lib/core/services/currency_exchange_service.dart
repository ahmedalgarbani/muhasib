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
      
      // Calculate exchange rate difference (profit/loss)
      final exchangeDifference = creditLocalAmount - debitLocalAmount;
      
      // Get next exchange number
      final exchangeNumber = await getNextExchangeNumber();
      
      // Start transaction
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
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
        
        // 2. Create journal entry for the exchange
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
          'total_debit': debitLocalAmount + (exchangeDifference < 0 ? -exchangeDifference : 0),
          'total_credit': creditLocalAmount + (exchangeDifference > 0 ? exchangeDifference : 0),
          'difference': 0.0,
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
        
        // 4. If there's an exchange difference, record it
        if (exchangeDifference.abs() > 0.01 && exchangeDifferenceAccountId != null) {
          if (exchangeDifference > 0) {
            // Profit from exchange - Credit to income
            await txn.insert('journal_entry_lines', {
              'journal_entry_id': journalEntryId,
              'line_number': lineNumber++,
              'account_id': exchangeDifferenceAccountId,
              'account_code': '',
              'account_name': '',
              'currency_id': null,
              'currency_code': '',
              'debit_amount': 0.0,
              'credit_amount': exchangeDifference,
              'notes': 'أرباح فروق صرف عملات',
            });
          } else {
            // Loss from exchange - Debit to expense
            await txn.insert('journal_entry_lines', {
              'journal_entry_id': journalEntryId,
              'line_number': lineNumber++,
              'account_id': exchangeDifferenceAccountId,
              'account_code': '',
              'account_name': '',
              'currency_id': null,
              'currency_code': '',
              'debit_amount': -exchangeDifference,
              'credit_amount': 0.0,
              'notes': 'خسائر فروق صرف عملات',
            });
          }
        }
        
        // 5. Update the exchange record with journal entry ID
        await txn.update(
          'currency_exchanges',
          {'journal_entry_id': journalEntryId},
          where: 'id = ?',
          whereArgs: [exchangeId],
        );
        
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
    
    // Close any previous active rate for this currency
    await txn.update(
      'currency_exchange_rates',
      {
        'end_date': effectiveDate.millisecondsSinceEpoch ~/ 1000,
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
      
      // Get the original local balance
      final localBalanceResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(
            (jel.debit_amount * COALESCE(c.exchange_rate, 1)) - 
            (jel.credit_amount * COALESCE(c.exchange_rate, 1))
          ), 0) as local_balance
        FROM journal_entry_lines jel
        INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
        LEFT JOIN currencies c ON c.id = jel.currency_id
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
        
        // Record the new exchange rate in history
        await _recordExchangeRateHistory(txn, currencyId, newExchangeRate, date);
        
        return Right(journalId);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء قيد إعادة التقييم: ${e.toString()}'));
    }
  }
}
