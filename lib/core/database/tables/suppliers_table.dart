import 'table_schema.dart';

class SuppliersTable implements TableSchema {
  @override
  String get tableName => 'suppliers';

  @override
  String get createTable => '''
    CREATE TABLE suppliers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      type INTEGER NOT NULL,
      contact TEXT NULL,
      contact_type INTEGER NULL,
      identity TEXT NULL,
      identity_type INTEGER NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      account_id INTEGER NULL REFERENCES accounts (id),
      payment_terms INTEGER NULL DEFAULT 30,
      current_balance REAL NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [];
}
