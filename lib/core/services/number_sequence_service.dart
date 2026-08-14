import 'package:sqflite/sqflite.dart';

/// Number Sequence Service
/// Generates unique sequential numbers for invoices, journal entries, etc.
/// Thread-safe with database-level locking
class NumberSequenceService {
  final Database _db;

  NumberSequenceService(this._db);

  /// Get next number for a sequence type (thread-safe)
  Future<String> getNextNumber(String sequenceType) async {
    return await _db.transaction((txn) async {
      try {
        await _ensureTableAndSequence(txn, sequenceType);

        // Read current sequence (with row-level lock)
        final result = await txn.query(
          'number_sequences',
          where: 'sequence_type = ?',
          whereArgs: [sequenceType],
          limit: 1,
        );

        if (result.isEmpty) {
          throw Exception('Sequence type not found: $sequenceType');
        }

        final sequence = result.first;
        final currentValue = sequence['current_value'] as int;
        final prefix = sequence['prefix'] as String?;
        final paddingLength = sequence['padding_length'] as int? ?? 6;
        final incrementBy = sequence['increment_by'] as int? ?? 1;
        final resetOnYearChange = (sequence['reset_on_year_change'] as int? ?? 0) == 1;
        final fiscalYear = sequence['fiscal_year'] as int?;

        int nextValue = currentValue + incrementBy;
        final now = DateTime.now();
        final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;

        // Check if we need to reset for new fiscal year
        if (resetOnYearChange) {
          final currentFiscalYear = now.year;
          
          if (fiscalYear != null && fiscalYear != currentFiscalYear) {
            // Reset to 1 for new fiscal year
            nextValue = 1;
            await txn.update(
              'number_sequences',
              {
                'current_value': nextValue,
                'fiscal_year': currentFiscalYear,
                'last_reset_date': nowTimestamp,
                'last_modification_time': nowTimestamp,
              },
              where: 'sequence_type = ?',
              whereArgs: [sequenceType],
            );
          } else {
            // Normal increment
            await txn.update(
              'number_sequences',
              {
                'current_value': nextValue,
                'last_modification_time': nowTimestamp,
              },
              where: 'sequence_type = ?',
              whereArgs: [sequenceType],
            );
          }
        } else {
          // Normal increment without fiscal year logic
          await txn.update(
            'number_sequences',
            {
              'current_value': nextValue,
              'last_modification_time': nowTimestamp,
            },
            where: 'sequence_type = ?',
            whereArgs: [sequenceType],
          );
        }

        // Format the number
        final paddedValue = nextValue.toString().padLeft(paddingLength, '0');
        return prefix != null ? '$prefix-$paddedValue' : paddedValue;
      } catch (e) {
        // Rollback will happen automatically if we throw
        rethrow;
      }
    });
  }

  /// Get current number without incrementing
  Future<String> getCurrentNumber(String sequenceType) async {
    await _ensureTableAndSequence(_db, sequenceType);

    final result = await _db.query(
      'number_sequences',
      where: 'sequence_type = ?',
      whereArgs: [sequenceType],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('Sequence type not found: $sequenceType');
    }

    final sequence = result.first;
    final currentValue = sequence['current_value'] as int;
    final prefix = sequence['prefix'] as String?;
    final paddingLength = sequence['padding_length'] as int? ?? 6;

    final paddedValue = currentValue.toString().padLeft(paddingLength, '0');
    return prefix != null ? '$prefix-$paddedValue' : paddedValue;
  }

  /// Get current raw value without incrementing
  Future<int> getCurrentValue(String sequenceType) async {
    await _ensureTableAndSequence(_db, sequenceType);

    final result = await _db.query(
      'number_sequences',
      where: 'sequence_type = ?',
      whereArgs: [sequenceType],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('Sequence type not found: $sequenceType');
    }

    return result.first['current_value'] as int;
  }

  Future<void> _ensureTableAndSequence(DatabaseExecutor executor, String sequenceType) async {
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS number_sequences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sequence_type TEXT NOT NULL UNIQUE,
        prefix TEXT,
        current_value INTEGER NOT NULL DEFAULT 0,
        min_value INTEGER DEFAULT 1,
        max_value INTEGER,
        increment_by INTEGER DEFAULT 1,
        padding_length INTEGER DEFAULT 6,
        fiscal_year INTEGER,
        reset_on_year_change INTEGER DEFAULT 0,
        last_reset_date INTEGER,
        creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
        last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
      );
    ''');
    try {
      await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_number_sequences_type ON number_sequences(sequence_type);',
      );
    } catch (_) {}

    final rows = await executor.query(
      'number_sequences',
      where: 'sequence_type = ?',
      whereArgs: [sequenceType],
      limit: 1,
    );

    if (rows.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final defaultPrefix = _getDefaultPrefix(sequenceType);
      await executor.rawInsert('''
        INSERT OR IGNORE INTO number_sequences 
          (sequence_type, prefix, current_value, padding_length, reset_on_year_change, creation_time, last_modification_time)
        VALUES (?, ?, 0, 6, 0, ?, ?)
      ''', [sequenceType, defaultPrefix, now, now]);
    }
  }

  String _getDefaultPrefix(String sequenceType) {
    switch (sequenceType) {
      case 'sales_invoice':
        return 'INV';
      case 'purchase_invoice':
        return 'PINV';
      case 'quotation':
        return 'QT';
      case 'journal_entry':
        return 'JE';
      case 'receipt_voucher':
        return 'RV';
      case 'payment_voucher':
        return 'PV';
      case 'sales_return':
        return 'SRT';
      case 'purchase_return':
        return 'PRT';
      case 'opening_balance':
        return 'OB';
      case 'stock_transfer':
        return 'TR';
      case 'stock_adjustment':
        return 'ADJ';
      default:
        return sequenceType.toUpperCase();
    }
  }

  /// Get next number formatted with an external prefix (e.g. from settings)
  /// while keeping the sequence's own padding.
  Future<String> getNextNumberWithPrefix(
    String sequenceType,
    String prefix,
  ) async {
    final full = await getNextNumber(sequenceType);
    final dashIndex = full.indexOf('-');
    final padded = dashIndex == -1 ? full : full.substring(dashIndex + 1);
    final normalizedPrefix = prefix.endsWith('-') ? prefix : '$prefix-';
    return '$normalizedPrefix$padded';
  }

  /// Reset sequence to a specific value
  Future<void> resetSequence(String sequenceType, int newValue) async {
    await _db.update(
      'number_sequences',
      {
        'current_value': newValue,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'sequence_type = ?',
      whereArgs: [sequenceType],
    );
  }

  /// Create or update a sequence
  Future<void> createOrUpdateSequence({
    required String sequenceType,
    String? prefix,
    int currentValue = 0,
    int paddingLength = 6,
    int incrementBy = 1,
    bool resetOnYearChange = false,
  }) async {
    final now = DateTime.now();
    final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;

    await _db.insert(
      'number_sequences',
      {
        'sequence_type': sequenceType,
        'prefix': prefix,
        'current_value': currentValue,
        'padding_length': paddingLength,
        'increment_by': incrementBy,
        'reset_on_year_change': resetOnYearChange ? 1 : 0,
        'fiscal_year': resetOnYearChange ? now.year : null,
        'creation_time': nowTimestamp,
        'last_modification_time': nowTimestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
