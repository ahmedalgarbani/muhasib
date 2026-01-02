import 'package:muhasib/core/errors/exceptions.dart';
import 'package:sqflite/sqflite.dart';

import '../models/journal_entry_line_model.dart';
import '../models/journal_entry_model.dart';

abstract class JournalLocalDataSource {
  Future<List<JournalEntryModel>> getJournalEntries();
  Future<JournalEntryModel> getJournalEntry(int id);
  Future<int> insertJournalEntry(JournalEntryModel entry);
  Future<void> updateJournalEntry(JournalEntryModel entry);
  Future<void> deleteJournalEntry(int id);
}

class JournalLocalDataSourceImpl implements JournalLocalDataSource {
  static const String _entriesTable = 'journal_entries';
  static const String _linesTable = 'journal_entry_lines';
  static const String _accountsTable = 'accounts';
  static const String _currenciesTable = 'currencies';

  final Database database;

  JournalLocalDataSourceImpl({required this.database});

  Future<void> _applyAccountBalanceDelta(
    DatabaseExecutor txn,
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

  Future<List<Map<String, dynamic>>> _getEntryLinesRaw(
    DatabaseExecutor txn,
    int entryId,
  ) async {
    return await txn.query(
      _linesTable,
      columns: ['account_id', 'debit_amount', 'credit_amount'],
      where: 'journal_entry_id = ?',
      whereArgs: [entryId],
    );
  }

  @override
  Future<List<JournalEntryModel>> getJournalEntries() async {
    try {
      final entries = await database.query(
        _entriesTable,
        orderBy: 'entry_date DESC, id DESC',
      );

      final List<JournalEntryModel> results = [];

      for (final entry in entries) {
        final lines = await database.query(
          _linesTable,
          where: 'journal_entry_id = ?',
          whereArgs: [entry['id']],
          orderBy: 'line_number ASC, id ASC',
        );

        final lineModels = lines
            .map((e) => JournalEntryLineModel.fromJson(e))
            .toList();

        results.add(JournalEntryModel.fromJson(entry, lines: lineModels));
      }

      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to load journal entries: ${e.toString()}',
      );
    }
  }

  @override
  Future<JournalEntryModel> getJournalEntry(int id) async {
    try {
      final entries = await database.query(
        _entriesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (entries.isEmpty) {
        throw LocalStorageException('Journal entry with id $id not found');
      }

      final lines = await database.query(
        _linesTable,
        where: 'journal_entry_id = ?',
        whereArgs: [id],
        orderBy: 'line_number ASC, id ASC',
      );

      final lineModels = lines
          .map((e) => JournalEntryLineModel.fromJson(e))
          .toList();

      return JournalEntryModel.fromJson(entries.first, lines: lineModels);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get journal entry: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> insertJournalEntry(JournalEntryModel entry) async {
    try {
      // Validate balance before insert
      final totalDebit = entry.lines.fold<double>(0, (sum, line) => sum + line.debit);
      final totalCredit = entry.lines.fold<double>(0, (sum, line) => sum + line.credit);
      final difference = (totalDebit - totalCredit).abs();
      
      if (difference > 0.01) {
        throw LocalStorageException(
          'القيد غير متوازن: المدين ($totalDebit) لا يساوي الدائن ($totalCredit)',
        );
      }
      
      if (entry.lines.isEmpty) {
        throw LocalStorageException('القيد يجب أن يحتوي على سطر واحد على الأقل');
      }
      
      return await database.transaction((txn) async {
        // Prepare entry data with timestamps
        final entryData = entry.toJson();
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        entryData['creation_time'] ??= nowSec;
        entryData['last_modification_time'] ??= nowSec;
        
        // Ensure totals are correct
        entryData['total_debit'] = totalDebit;
        entryData['total_credit'] = totalCredit;
        entryData['difference'] = difference;
        
        final entryId = await txn.insert(
          _entriesTable,
          entryData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        for (final lineEntity in entry.lines) {
          final lineModel = lineEntity is JournalEntryLineModel
              ? lineEntity
              : JournalEntryLineModel.fromEntity(lineEntity);
          final payload = await _buildLinePayload(txn, lineModel, entryId);

          await txn.insert(
            _linesTable,
            payload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          // Update account balance for this line (debit - credit)
          final accountId = payload['account_id'] as int?;
          if (accountId != null) {
            final debit = (payload['debit_amount'] as num?)?.toDouble() ?? 0.0;
            final credit = (payload['credit_amount'] as num?)?.toDouble() ?? 0.0;
            final delta = debit - credit;
            if (delta != 0) {
              await _applyAccountBalanceDelta(txn, accountId, delta);
            }
          }
        }

        return entryId;
      });
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to insert journal entry: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateJournalEntry(JournalEntryModel entry) async {
    if (entry.id == null) {
      throw LocalStorageException('Journal entry id is required for update');
    }

    try {
      // Validate balance before update
      final totalDebit = entry.lines.fold<double>(0, (sum, line) => sum + line.debit);
      final totalCredit = entry.lines.fold<double>(0, (sum, line) => sum + line.credit);
      final difference = (totalDebit - totalCredit).abs();
      
      if (difference > 0.01) {
        throw LocalStorageException(
          'القيد غير متوازن: المدين ($totalDebit) لا يساوي الدائن ($totalCredit)',
        );
      }
      
      if (entry.lines.isEmpty) {
        throw LocalStorageException('القيد يجب أن يحتوي على سطر واحد على الأقل');
      }
      
      await database.transaction((txn) async {
        // Check if entry is posted - allow update but track modification
        final existingEntry = await txn.query(
          _entriesTable,
          columns: ['is_posted'],
          where: 'id = ?',
          whereArgs: [entry.id],
          limit: 1,
        );
        
        final wasPosted = existingEntry.isNotEmpty && 
            (existingEntry.first['is_posted'] as int?) == 1;
        
        // Reverse old balances before replacing lines
        final oldLines = await _getEntryLinesRaw(txn, entry.id!);
        for (final l in oldLines) {
          final accountId = l['account_id'] as int;
          final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
          final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;
          final delta = debit - credit;
          if (delta != 0) {
            await _applyAccountBalanceDelta(txn, accountId, -delta);
          }
        }

        final payload = entry.toJson();
        payload['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final updatedRows = await txn.update(
          _entriesTable,
          payload,
          where: 'id = ?',
          whereArgs: [entry.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        if (updatedRows == 0) {
          throw LocalStorageException(
            'Journal entry with id ${entry.id} was not found',
          );
        }

        await txn.delete(
          _linesTable,
          where: 'journal_entry_id = ?',
          whereArgs: [entry.id],
        );

        for (final lineEntity in entry.lines) {
          final lineModel = lineEntity is JournalEntryLineModel
              ? lineEntity
              : JournalEntryLineModel.fromEntity(lineEntity);
          final payload = await _buildLinePayload(
            txn,
            lineModel,
            entry.id as int,
          );

          await txn.insert(
            _linesTable,
            payload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          // Apply new balances
          final accountId = payload['account_id'] as int?;
          if (accountId != null) {
            final debit = (payload['debit_amount'] as num?)?.toDouble() ?? 0.0;
            final credit = (payload['credit_amount'] as num?)?.toDouble() ?? 0.0;
            final delta = debit - credit;
            if (delta != 0) {
              await _applyAccountBalanceDelta(txn, accountId, delta);
            }
          }
        }
      });
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to update journal entry: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteJournalEntry(int id) async {
    try {
      final deleted = await database.transaction((txn) async {
        // Reverse balances before delete
        final oldLines = await _getEntryLinesRaw(txn, id);
        for (final l in oldLines) {
          final accountId = l['account_id'] as int;
          final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
          final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;
          final delta = debit - credit;
          if (delta != 0) {
            await _applyAccountBalanceDelta(txn, accountId, -delta);
          }
        }
        return await txn.delete(
          _entriesTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      if (deleted == 0) {
        throw LocalStorageException('Journal entry with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(
        'Failed to delete journal entry: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> _buildLinePayload(
    DatabaseExecutor txn,
    JournalEntryLineModel line,
    int entryId,
  ) async {
    final payload = line.toJson(journalEntryId: entryId);

    if (payload['account_id'] == null) {
      final account = await txn.query(
        _accountsTable,
        columns: ['id', 'code'],
        where: 'name = ?',
        whereArgs: [line.accountName],
        limit: 1,
      );

      if (account.isNotEmpty) {
        payload['account_id'] = account.first['id'];
        payload['account_code'] = account.first['code'];
      }
    }

    if (payload['currency_id'] == null) {
      final currency = await txn.query(
        _currenciesTable,
        columns: ['id'],
        where: 'code = ?',
        whereArgs: [line.currencyCode],
        limit: 1,
      );

      if (currency.isNotEmpty) {
        payload['currency_id'] = currency.first['id'];
      }
    }

    return payload;
  }
}
