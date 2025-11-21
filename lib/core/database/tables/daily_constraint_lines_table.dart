import 'table_schema.dart';

class DailyConstraintLinesTable implements TableSchema {
  @override
  String get tableName => 'daily_constraint_lines';

  @override
  String get createTable => '''
    CREATE TABLE daily_constraint_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      amount REAL NOT NULL,
      local_amount REAL NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      statement TEXT NOT NULL,
      image_path TEXT NULL,
      credit_account_id INTEGER NOT NULL REFERENCES accounts (id),
      debit_account_id INTEGER NOT NULL REFERENCES accounts (id),
      daily_constraint_id INTEGER NULL REFERENCES daily_constraints (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
