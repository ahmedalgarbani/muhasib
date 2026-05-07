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
