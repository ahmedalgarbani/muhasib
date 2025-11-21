import 'table_schema.dart';

class VouchersTable implements TableSchema {
  @override
  String get tableName => 'vouchers';

  @override
  String get createTable => '''
    CREATE TABLE vouchers (
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
      type INTEGER NOT NULL,
      number INTEGER NOT NULL,
      date INTEGER NOT NULL,
      statement TEXT NOT NULL,
      is_posted INTEGER NOT NULL CHECK (is_posted IN (0, 1)),
      reference_number TEXT NOT NULL,
      amount REAL NULL,
      local_amount REAL NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      account_id INTEGER NOT NULL REFERENCES accounts (id),
      u_no TEXT NULL,
      parent_number TEXT NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      image_path TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
