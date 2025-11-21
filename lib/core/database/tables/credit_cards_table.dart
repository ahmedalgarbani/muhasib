import 'table_schema.dart';

class CreditCardsTable implements TableSchema {
  @override
  String get tableName => 'credit_cards';

  @override
  String get createTable => '''
    CREATE TABLE credit_cards (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      statement TEXT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      has_commission INTEGER NOT NULL DEFAULT 1 CHECK (has_commission IN (0, 1)),
      commission_ratio REAL NULL,
      commission_bearing_method INTEGER NOT NULL,
      commission_account_id INTEGER NULL REFERENCES accounts (id),
      bank_tax_ratio REAL NULL,
      bank_id INTEGER NOT NULL REFERENCES banks (id) ON DELETE CASCADE,
      card_type TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
