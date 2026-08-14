import 'table_schema.dart';

class NumberSequencesTable implements TableSchema {
  @override
  String get tableName => 'number_sequences';

  @override
  String get createTable => '''
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
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX IF NOT EXISTS idx_number_sequences_type ON number_sequences(sequence_type);',
      ];
}
