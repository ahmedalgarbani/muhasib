import 'table_schema.dart';

class JournalEntriesTable implements TableSchema {
  @override
  String get tableName => 'journal_entries';

  @override
  String get createTable => '''
    CREATE TABLE journal_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number TEXT NULL,
      entry_date INTEGER NOT NULL,
      description TEXT NULL,
      reference_type TEXT NULL,
      reference_id INTEGER NULL,
      reference_number TEXT NULL,
      notes TEXT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      is_posted INTEGER NOT NULL DEFAULT 0 CHECK (is_posted IN (0, 1)),
      total_debit REAL NOT NULL DEFAULT 0.0,
      total_credit REAL NOT NULL DEFAULT 0.0,
      difference REAL NOT NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX idx_journal_entries_number ON journal_entries(number);',
        'CREATE INDEX idx_journal_entries_date ON journal_entries(entry_date);',
      ];
}
