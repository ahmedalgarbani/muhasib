import 'table_schema.dart';

class CreditCardPaymentMethodsTable implements TableSchema {
  @override
  String get tableName => 'credit_card_payment_methods';

  @override
  String get createTable => '''
    CREATE TABLE credit_card_payment_methods (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      credit_card_ratio INTEGER NULL,
      credit_card_amount REAL NULL,
      credit_card_id INTEGER NULL REFERENCES credit_cards (id),
      bank_tax_ratio INTEGER NULL,
      bank_tax_amount REAL NULL,
      amount REAL NULL,
      statement TEXT NOT NULL,
      payment_method_id INTEGER NULL REFERENCES payment_methods (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
