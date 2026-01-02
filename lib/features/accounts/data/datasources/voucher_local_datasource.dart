import 'package:muhasib/core/errors/exceptions.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/voucher_entity.dart';
import '../models/voucher_model.dart';

abstract class VoucherLocalDataSource {
  Future<List<VoucherModel>> getVouchers({VoucherType? type});
  Future<VoucherModel> getVoucher(int id);
  Future<int> insertVoucher(VoucherModel voucher);
  Future<void> updateVoucher(VoucherModel voucher);
  Future<void> deleteVoucher(int id);
  Future<int> generateVoucherNumber(VoucherType type);
}

class VoucherLocalDataSourceImpl implements VoucherLocalDataSource {
  static const String _vouchersTable = 'vouchers';
  static const String _voucherLinesTable = 'voucher_lines';
  static const String _accountsTable = 'accounts';
  static const String _currenciesTable = 'currencies';
  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalLinesTable = 'journal_entry_lines';
  static const String _accountLimitsTable = 'account_limits';
  static const String _accountLimitLogsTable = 'account_limit_logs';

  final Database database;

  VoucherLocalDataSourceImpl({required this.database});

  Future<int?> _resolveCurrencyId(Transaction txn, int? desiredId) async {
    if (desiredId != null) {
      final rows = await txn.query(
        _currenciesTable,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [desiredId],
        limit: 1,
      );
      if (rows.isNotEmpty) return desiredId;
    }
    final any = await txn.query(
      _currenciesTable,
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (any.isEmpty) return null;
    return any.first['id'] as int;
  }

  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
    final rows = await txn.query(
      _accountsTable,
      columns: ['id', 'code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw LocalStorageException('Account not found: id=$accountId');
    }
    return rows.first;
  }

  Future<void> _applyAccountBalanceDelta(
    Transaction txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      _accountsTable,
      columns: ['balance', 'local_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw LocalStorageException('Account not found: id=$accountId');
    }
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = current + delta;
    await txn.update(
      _accountsTable,
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> _validateAccountLimits({
    required Transaction txn,
    required int currencyId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final violations = <String>[];
    for (final l in lines) {
      final accountId = l['account_id'] as int;
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      if (debit <= 0 && credit <= 0) continue;

      final limitRows = await txn.query(
        _accountLimitsTable,
        columns: ['debit_limit', 'credit_limit', 'current_debit', 'current_credit', 'is_active'],
        where: 'account_id = ? AND currency_id = ?',
        whereArgs: [accountId, currencyId],
        limit: 1,
      );
      if (limitRows.isEmpty) continue;
      final limit = limitRows.first;
      final isActive = (limit['is_active'] as int?) ?? 1;
      if (isActive != 1) continue;

      final debitLimit = (limit['debit_limit'] as num?)?.toDouble() ?? 0.0;
      final creditLimit = (limit['credit_limit'] as num?)?.toDouble() ?? 0.0;
      final currentDebit = (limit['current_debit'] as num?)?.toDouble() ?? 0.0;
      final currentCredit = (limit['current_credit'] as num?)?.toDouble() ?? 0.0;

      if (debitLimit > 0 && currentDebit + debit > debitLimit + 0.000001) {
        violations.add('تجاوز حد المدين للحساب $accountId');
      }
      if (creditLimit > 0 && currentCredit + credit > creditLimit + 0.000001) {
        violations.add('تجاوز حد الدائن للحساب $accountId');
      }
    }
    if (violations.isNotEmpty) {
      throw LocalStorageException(violations.join('\n'));
    }
  }

  Future<void> _applyAccountLimitUsageDelta({
    required Transaction txn,
    required int currencyId,
    required List<Map<String, dynamic>> lines,
    required int transactionDateSec,
    required String transactionType,
    required int transactionId,
    required String? description,
    required int multiplier, // +1 apply, -1 reverse
  }) async {
    for (final l in lines) {
      final accountId = l['account_id'] as int;
      final debit = ((l['debit_amount'] as num?)?.toDouble() ?? 0.0) * multiplier;
      final credit = ((l['credit_amount'] as num?)?.toDouble() ?? 0.0) * multiplier;

      if (debit == 0 && credit == 0) continue;

      // Update usage if row exists and active. Allow negative deltas on reverse.
      await txn.rawUpdate(
        '''
UPDATE $_accountLimitsTable
SET current_debit = current_debit + ?,
    current_credit = current_credit + ?,
    last_modification_time = ?
WHERE account_id = ? AND currency_id = ? AND is_active = 1
''',
        [
          debit,
          credit,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          accountId,
          currencyId,
        ],
      );

      // Log
      await txn.insert(
        _accountLimitLogsTable,
        {
          'account_id': accountId,
          'currency_id': currencyId,
          'debit_amount': debit,
          'credit_amount': credit,
          'transaction_date': transactionDateSec,
          'transaction_type': transactionType,
          'transaction_id': transactionId,
          'description': description,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<int?> _findJournalEntryIdForVoucher(Transaction txn, int voucherId) async {
    final rows = await txn.query(
      _journalEntriesTable,
      columns: ['id'],
      where: 'reference_type IN (?, ?) AND reference_id = ?',
      whereArgs: ['voucher_receipt', 'voucher_payment', voucherId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  Future<void> _reversePostedVoucherAccounting(Transaction txn, int voucherId) async {
    final journalEntryId = await _findJournalEntryIdForVoucher(txn, voucherId);
    if (journalEntryId == null) return;

    // Load journal lines to reverse balances/limits before deleting
    final lines = await txn.query(
      _journalLinesTable,
      columns: ['account_id', 'debit_amount', 'credit_amount', 'currency_id'],
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
      orderBy: 'line_number ASC, id ASC',
    );

    // Reverse account balances
    for (final l in lines) {
      final accountId = l['account_id'] as int;
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;
      final delta = (debit - credit);
      if (delta != 0) {
        await _applyAccountBalanceDelta(txn, accountId, -delta);
      }
    }

    // Reverse limits if currency_id is present
    final firstCurrencyId = lines.isNotEmpty ? (lines.first['currency_id'] as int?) : null;
    if (firstCurrencyId != null) {
      final mapped = lines
          .map((l) => {
                'account_id': l['account_id'],
                'debit_amount': l['debit_amount'],
                'credit_amount': l['credit_amount'],
              })
          .toList();
      await _applyAccountLimitUsageDelta(
        txn: txn,
        currencyId: firstCurrencyId,
        lines: mapped,
        transactionDateSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        transactionType: 'voucher_reverse',
        transactionId: voucherId,
        description: 'عكس أثر سند (voucherId=$voucherId)',
        multiplier: -1,
      );
    }

    // Delete journal entry (cascades lines if FK set; but lines table has ON DELETE CASCADE via journal_entry_id? yes)
    await txn.delete(
      _journalEntriesTable,
      where: 'id = ?',
      whereArgs: [journalEntryId],
    );
  }

  Future<void> _postVoucherToJournal({
    required Transaction txn,
    required int voucherId,
    required Map<String, dynamic> voucherData,
    required List<VoucherLineModel> voucherLines,
  }) async {
    final type = VoucherType.fromValue((voucherData['type'] as int?) ?? 1);
    final voucherNumber = (voucherData['number'] as int?) ?? 0;
    final statement = (voucherData['statement'] as String?) ?? type.label;

    // entry_date in vouchers is stored in seconds
    final rawDate = (voucherData['date'] as int?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final entryDateSec = rawDate > 1000000000000 ? (rawDate ~/ 1000) : rawDate;

    final int cashOrBankAccountId = voucherData['account_id'] as int;

    // Determine currency
    final currencyId = await _resolveCurrencyId(txn, voucherData['currency_id'] as int?);

    // Validate/derive amount vs sum(lines)
    final sumLines = voucherLines.fold<double>(0.0, (s, l) => s + ((l.amount ?? 0.0)));
    double amount = (voucherData['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) amount = sumLines;
    if ((amount - sumLines).abs() > 0.01) {
      throw LocalStorageException('مجموع بنود السند (${sumLines.toStringAsFixed(2)}) لا يساوي مبلغ السند (${amount.toStringAsFixed(2)})');
    }

    // Build journal lines (debit_amount/credit_amount)
    final journalLines = <Map<String, dynamic>>[];

    // Cash/Bank line first
    final cashMeta = await _getAccountMeta(txn, cashOrBankAccountId);
    journalLines.add({
      'line_number': 1,
      'account_id': cashOrBankAccountId,
      'account_code': cashMeta['code'],
      'account_name': cashMeta['name'],
      'currency_id': currencyId,
      'currency_code': voucherData['currency_code'],
      'debit_amount': type == VoucherType.receipt ? amount : 0.0,
      'credit_amount': type == VoucherType.payment ? amount : 0.0,
      'notes': statement,
    });

    // Counterpart lines
    int ln = 2;
    for (final vl in voucherLines) {
      final lineAmount = (vl.amount ?? 0.0);
      if (lineAmount <= 0) continue;
      final accountId = vl.accountId;
      if (accountId == null) {
        throw LocalStorageException('يجب اختيار حساب لكل بند في السند');
      }
      final meta = await _getAccountMeta(txn, accountId);
      journalLines.add({
        'line_number': ln++,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'currency_id': currencyId,
        'currency_code': voucherData['currency_code'],
        'debit_amount': type == VoucherType.payment ? lineAmount : 0.0,
        'credit_amount': type == VoucherType.receipt ? lineAmount : 0.0,
        'notes': (vl.statement.isNotEmpty ? vl.statement : statement),
      });
    }

    // Totals check
    final totalDebit = journalLines.fold<double>(0.0, (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0));
    final totalCredit = journalLines.fold<double>(0.0, (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0));
    final diff = (totalDebit - totalCredit).abs();
    if (diff > 0.01) {
      throw LocalStorageException('قيد غير متوازن للسند رقم $voucherNumber (فرق: ${diff.toStringAsFixed(2)})');
    }

    // Validate account limits (if currency is known)
    if (currencyId != null) {
      await _validateAccountLimits(txn: txn, currencyId: currencyId, lines: journalLines);
    }

    final journalNumberPrefix = type == VoucherType.receipt ? 'RV' : 'PV';
    final journalNumber = '$journalNumberPrefix-${voucherNumber.toString().padLeft(6, '0')}';
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final entryId = await txn.insert(
      _journalEntriesTable,
      {
        'number': journalNumber,
        'entry_date': entryDateSec,
        'description': statement,
        'reference_type': type == VoucherType.receipt ? 'voucher_receipt' : 'voucher_payment',
        'reference_id': voucherId,
        'reference_number': voucherData['reference_number'],
        'notes': voucherData['statement'],
        'status': 0,
        'is_posted': 1,
        'total_debit': totalDebit,
        'total_credit': totalCredit,
        'difference': 0.0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    // Insert journal lines
    for (final jl in journalLines) {
      await txn.insert(
        _journalLinesTable,
        {
          'journal_entry_id': entryId,
          'line_number': jl['line_number'],
          'account_id': jl['account_id'],
          'account_code': jl['account_code'],
          'account_name': jl['account_name'],
          'currency_id': jl['currency_id'],
          'currency_code': jl['currency_code'],
          'debit_amount': jl['debit_amount'],
          'credit_amount': jl['credit_amount'],
          'notes': jl['notes'],
          'description': jl['notes'],
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }

    // Update account balances
    for (final jl in journalLines) {
      final accountId = jl['account_id'] as int;
      final debit = (jl['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (jl['credit_amount'] as num?)?.toDouble() ?? 0.0;
      final delta = debit - credit;
      if (delta != 0) {
        await _applyAccountBalanceDelta(txn, accountId, delta);
      }
    }

    // Update limits usage and log (if currency known)
    if (currencyId != null) {
      await _applyAccountLimitUsageDelta(
        txn: txn,
        currencyId: currencyId,
        lines: journalLines,
        transactionDateSec: entryDateSec,
        transactionType: type == VoucherType.receipt ? 'voucher_receipt' : 'voucher_payment',
        transactionId: voucherId,
        description: statement,
        multiplier: 1,
      );
    }
  }

  @override
  Future<List<VoucherModel>> getVouchers({VoucherType? type}) async {
    try {
      final whereClause = type != null ? 'WHERE v.type = ?' : '';
      final whereArgs = type != null ? [type.value] : <Object?>[];

      final rows = await database.rawQuery(
        '''
        SELECT v.*, a.name AS account_name
        FROM $_vouchersTable v
        LEFT JOIN $_accountsTable a ON a.id = v.account_id
        $whereClause
        ORDER BY v.date DESC, v.id DESC
        ''',
        whereArgs,
      );

      final vouchers = <VoucherModel>[];

      for (final row in rows) {
        final lines = await _getVoucherLines(row['id'] as int);
        vouchers.add(VoucherModel.fromJson(row, lines: lines));
      }

      return vouchers;
    } catch (e) {
      throw LocalStorageException(
        'Failed to load vouchers: ${e.toString()}',
      );
    }
  }

  @override
  Future<VoucherModel> getVoucher(int id) async {
    try {
      final rows = await database.rawQuery(
        '''
        SELECT v.*, a.name AS account_name
        FROM $_vouchersTable v
        LEFT JOIN $_accountsTable a ON a.id = v.account_id
        WHERE v.id = ?
        LIMIT 1
        ''',
        [id],
      );

      if (rows.isEmpty) {
        throw LocalStorageException('Voucher with id $id not found');
      }

      final lines = await _getVoucherLines(id);
      return VoucherModel.fromJson(rows.first, lines: lines);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> insertVoucher(VoucherModel voucher) async {
    try {
      // Validate voucher before insert
      if (voucher.lines.isEmpty) {
        throw LocalStorageException('السند يجب أن يحتوي على بند واحد على الأقل');
      }
      
      if (voucher.amount <= 0) {
        throw LocalStorageException('مبلغ السند يجب أن يكون أكبر من صفر');
      }
      
      return await database.transaction((txn) async {
        // Validate main account exists and is active
        final accountCheck = await txn.query(
          _accountsTable,
          columns: ['id', 'is_active', 'is_master'],
          where: 'id = ?',
          whereArgs: [voucher.accountId],
          limit: 1,
        );
        
        if (accountCheck.isEmpty) {
          throw LocalStorageException('حساب الصندوق/البنك (id=${voucher.accountId}) غير موجود');
        }
        
        final account = accountCheck.first;
        if ((account['is_active'] as int?) != 1) {
          throw LocalStorageException('حساب الصندوق/البنك غير نشط');
        }
        if ((account['is_master'] as int?) == 1) {
          throw LocalStorageException('لا يمكن استخدام حساب رئيسي للسندات');
        }
        
        // Validate line accounts exist
        for (final line in voucher.lines) {
          if (line.accountId == null) continue;
          final lineAccountCheck = await txn.query(
            _accountsTable,
            columns: ['id', 'is_active'],
            where: 'id = ?',
            whereArgs: [line.accountId],
            limit: 1,
          );
          if (lineAccountCheck.isEmpty) {
            throw LocalStorageException('الحساب المقابل (id=${line.accountId}) غير موجود');
          }
          if ((lineAccountCheck.first['is_active'] as int?) != 1) {
            throw LocalStorageException('الحساب المقابل غير نشط');
          }
        }
        
        // Check for duplicate voucher number
        final duplicateCheck = await txn.query(
          _vouchersTable,
          columns: ['id'],
          where: 'type = ? AND number = ?',
          whereArgs: [voucher.type.value, voucher.number],
          limit: 1,
        );
        
        if (duplicateCheck.isNotEmpty) {
          throw LocalStorageException(
            'رقم السند ${voucher.number} موجود مسبقًا لنفس النوع. يرجى استخدام رقم مختلف.',
          );
        }
        
        final payload = voucher.toJson();
        // Force posted vouchers to ensure accounting compliance & report visibility.
        payload['is_posted'] = 1;
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        payload['creation_time'] ??= nowSec;
        payload['last_modification_time'] ??= nowSec;

        final voucherId = await txn.insert(
          _vouchersTable,
          payload,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        for (final line in voucher.lines) {
          final model =
              line is VoucherLineModel ? line : VoucherLineModel.fromEntity(line);
          final linePayload = model.toJson(voucherId: voucherId);

          await txn.insert(
            _voucherLinesTable,
            linePayload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // Post voucher to journal, update balances and limits (atomic)
        await _postVoucherToJournal(
          txn: txn,
          voucherId: voucherId,
          voucherData: {
            ...payload,
            'id': voucherId,
          },
          voucherLines: voucher.lines
              .map((e) => e is VoucherLineModel ? e : VoucherLineModel.fromEntity(e))
              .toList(),
        );

        return voucherId;
      });
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to insert voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateVoucher(VoucherModel voucher) async {
    if (voucher.id == null) {
      throw LocalStorageException('Voucher id is required for update');
    }

    try {
      await database.transaction((txn) async {
        // Reverse previous posted accounting impact (if any)
        await _reversePostedVoucherAccounting(txn, voucher.id!);

        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final updated = await txn.update(
          _vouchersTable,
          {
            ...voucher.toJson(),
            'is_posted': 1,
            'last_modification_time': nowSec,
          },
          where: 'id = ?',
          whereArgs: [voucher.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        if (updated == 0) {
          throw LocalStorageException(
            'Voucher with id ${voucher.id} was not found',
          );
        }

        await txn.delete(
          _voucherLinesTable,
          where: 'vouchers_id = ?',
          whereArgs: [voucher.id],
        );

        for (final line in voucher.lines) {
          final model =
              line is VoucherLineModel ? line : VoucherLineModel.fromEntity(line);
          final payload = model.toJson(voucherId: voucher.id!);

          await txn.insert(
            _voucherLinesTable,
            payload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // Re-post with new data
        await _postVoucherToJournal(
          txn: txn,
          voucherId: voucher.id!,
          voucherData: {
            ...voucher.toJson(),
            'id': voucher.id,
            'is_posted': 1,
          },
          voucherLines: voucher.lines
              .map((e) => e is VoucherLineModel ? e : VoucherLineModel.fromEntity(e))
              .toList(),
        );
      });
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to update voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteVoucher(int id) async {
    try {
      final deleted = await database.transaction((txn) async {
        // Reverse posted accounting impact (if any)
        await _reversePostedVoucherAccounting(txn, id);
        return await txn.delete(
          _vouchersTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      if (deleted == 0) {
        throw LocalStorageException('Voucher with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to delete voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> generateVoucherNumber(VoucherType type) async {
    try {
      final result = await database.rawQuery(
        '''
        SELECT COALESCE(MAX(number), 0) + 1 AS next_number
        FROM $_vouchersTable
        WHERE type = ?
        ''',
        [type.value],
      );

      if (result.isEmpty) return 1;
      final value = result.first['next_number'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 1;
    } catch (e) {
      throw LocalStorageException(
        'Failed to generate voucher number: ${e.toString()}',
      );
    }
  }

  Future<List<VoucherLineModel>> _getVoucherLines(int voucherId) async {
    final lines = await database.rawQuery(
      '''
      SELECT vl.*, a.name AS account_name
      FROM $_voucherLinesTable vl
      LEFT JOIN $_accountsTable a ON a.id = vl.account_id
      WHERE vl.vouchers_id = ?
      ORDER BY vl.id ASC
      ''',
      [voucherId],
    );

    return lines.map((e) => VoucherLineModel.fromJson(e)).toList();
  }
}

