import 'table_schema.dart';

class DailyConstraintsTable implements TableSchema {
  @override
  String get tableName => 'daily_constraints';

  @override
  String get createTable => '''
    CREATE TABLE daily_constraints (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number INTEGER NOT NULL,
      date INTEGER NOT NULL,
      statement TEXT NULL,
      total_amount REAL NOT NULL,
      exchange_rate REAL NULL,
      currency_code TEXT NULL,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      parent_number INTEGER NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      u_no TEXT NULL,
      constraint_type INTEGER NOT NULL DEFAULT 0
    );
  ''';

  @override
  List<String> get indexes => [];
}
