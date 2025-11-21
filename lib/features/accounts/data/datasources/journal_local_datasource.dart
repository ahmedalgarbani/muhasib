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
      return await database.transaction((txn) async {
        // Prepare entry data with timestamps
        final entryData = entry.toJson();
        entryData['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
        entryData['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
        
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
        }

        return entryId;
      });
    } catch (e) {
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
      await database.transaction((txn) async {
        final updatedRows = await txn.update(
          _entriesTable,
          entry.toJson(),
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
        }
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to update journal entry: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteJournalEntry(int id) async {
    try {
      final deleted = await database.delete(
        _entriesTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deleted == 0) {
        throw LocalStorageException('Journal entry with id $id not found');
      }
    } catch (e) {
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
    
    // Ensure timestamps are set
    payload['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
    payload['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;

    return payload;
  }
}
