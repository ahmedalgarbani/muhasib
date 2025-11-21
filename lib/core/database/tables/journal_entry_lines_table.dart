import 'table_schema.dart';

class JournalEntryLinesTable implements TableSchema {
  @override
  String get tableName => 'journal_entry_lines';

  @override
  String get createTable => '''
    CREATE TABLE journal_entry_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      journal_entry_id INTEGER NOT NULL REFERENCES journal_entries (id) ON DELETE CASCADE,
      line_number INTEGER NOT NULL,
      account_id INTEGER NULL REFERENCES accounts (id),
      account_code TEXT NULL,
      account_name TEXT NOT NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      currency_code TEXT NOT NULL,
      debit REAL NOT NULL DEFAULT 0.0,
      credit REAL NOT NULL DEFAULT 0.0,
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX idx_journal_entry_lines_entry ON journal_entry_lines(journal_entry_id);',
        'CREATE INDEX idx_journal_entry_lines_account ON journal_entry_lines(account_id);',
      ];
}
