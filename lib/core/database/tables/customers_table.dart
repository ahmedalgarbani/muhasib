import 'table_schema.dart';

class CustomersTable implements TableSchema {
  @override
  String get tableName => 'customers';

  @override
  String get createTable => '''
    CREATE TABLE customers (
      other_creator_id INTEGER NULL,
      other_id INTEGER NULL,
      other_number INTEGER NULL,
      other_creation_time INTEGER NULL,
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      type INTEGER NOT NULL,
      classification INTEGER NOT NULL,
      contact TEXT NULL,
      contact_type INTEGER NULL,
      send_message_method INTEGER NULL,
      identity TEXT NULL,
      identity_type INTEGER NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      account_id INTEGER NULL REFERENCES accounts (id),
      city_id INTEGER NULL REFERENCES cities (id),
      classification_id INTEGER NOT NULL REFERENCES classifications (id),
      credit_limit REAL NULL DEFAULT 0.0,
      current_balance REAL NULL DEFAULT 0.0,
      loyalty_points REAL NULL DEFAULT 0.0,
      last_purchase_date INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_customers_name ON customers(name);',
  ];
}
