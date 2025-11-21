import 'table_schema.dart';

class OpeningEntriesTable implements TableSchema {
  @override
  String get tableName => 'opening_entries';

  @override
  String get createTable => '''
    CREATE TABLE opening_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number INTEGER NOT NULL,
      credit_amount REAL NULL,
      credit_local_amount REAL NULL,
      debit_amount REAL NULL,
      debit_local_amount REAL NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      date INTEGER NOT NULL,
      statement TEXT NOT NULL,
      parent_number TEXT NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      u_no TEXT NULL,
      opening_entry_show_type INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
