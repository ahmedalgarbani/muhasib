import 'table_schema.dart';

class OpeningEntryLinesTable implements TableSchema {
  @override
  String get tableName => 'opening_entry_lines';

  @override
  String get createTable => '''
    CREATE TABLE opening_entry_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      amount REAL NULL,
      local_amount REAL NULL,
      type INTEGER NOT NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      statement TEXT NULL,
      image_path TEXT NULL,
      account_id INTEGER NOT NULL REFERENCES accounts (id),
      opening_entry_id INTEGER NULL REFERENCES opening_entries (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
