import 'table_schema.dart';

class JournalEntryLinesTable implements TableSchema {
  @override
  String get tableName => 'journal_entry_lines';

  @override
  String get createTable => '''
    CREATE TABLE journal_entry_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      journal_entry_id INTEGER NOT NULL REFERENCES journal_entries (id) ON DELETE CASCADE,
      line_number INTEGER NULL,
      account_id INTEGER NOT NULL REFERENCES accounts (id),
      account_code TEXT NULL,
      account_name TEXT NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      currency_code TEXT NULL,
      debit_amount REAL NOT NULL DEFAULT 0.0,
      credit_amount REAL NOT NULL DEFAULT 0.0,
      description TEXT NULL,
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX idx_journal_entry_lines_entry ON journal_entry_lines(journal_entry_id);',
        'CREATE INDEX idx_journal_entry_lines_account ON journal_entry_lines(account_id);',
      ];
}
